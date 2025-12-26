using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Azure;
using Azure.AI.ContentSafety;
using Azure.Core;
using Microsoft.Extensions.Options;
using ZavaStorefront.Models;

namespace ZavaStorefront.Services;

public class FoundryChatService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<FoundryChatService> _logger;
    private readonly FoundryOptions _options;
    private readonly TokenCredential _credential;
    private readonly ContentSafetyClient _contentSafetyClient;
    private static readonly JsonSerializerOptions _jsonOptions = new(JsonSerializerDefaults.Web);

    public FoundryChatService(HttpClient httpClient, IOptions<FoundryOptions> options, IOptions<ContentSafetyOptions> safetyOptions, ILogger<FoundryChatService> logger, TokenCredential credential)
    {
        _httpClient = httpClient;
        _logger = logger;
        _options = options.Value;
        _credential = credential;

        var csOpts = safetyOptions.Value;
        var csEndpoint = csOpts.Endpoint ?? throw new InvalidOperationException("AZURE_CONTENT_SAFETY_ENDPOINT / ContentSafety:Endpoint is not configured.");
        var csEndpointUri = new Uri(csEndpoint);

        if (csEndpointUri.Host.EndsWith("api.cognitive.microsoft.com", StringComparison.OrdinalIgnoreCase))
        {
            var key = csOpts.ApiKey ?? throw new InvalidOperationException("Content Safety regional endpoints require an API key. Set AZURE_CONTENT_SAFETY_KEY or switch to a custom subdomain endpoint to use managed identity.");
            _logger.LogInformation("Using API key authentication for Content Safety because a regional endpoint was provided.");
            _contentSafetyClient = new ContentSafetyClient(csEndpointUri, new AzureKeyCredential(key));
        }
        else
        {
            _logger.LogInformation("Using managed identity authentication for Content Safety.");
            _contentSafetyClient = new ContentSafetyClient(csEndpointUri, credential);
        }
    }

    public async Task<string> GetChatCompletionAsync(string prompt, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(prompt))
        {
            throw new ArgumentException("Prompt cannot be empty.", nameof(prompt));
        }

        var isSafe = await EvaluateSafetyAsync(prompt, cancellationToken);
        if (!isSafe)
        {
            return "Sorry, I can’t help with that request.";
        }

        var endpoint = _options.Endpoint?.TrimEnd('/') ?? throw new InvalidOperationException("AZURE_FOUNDRY_ENDPOINT / Foundry:Endpoint is not configured.");
        if (!Uri.TryCreate(endpoint, UriKind.Absolute, out var endpointUri))
        {
            throw new InvalidOperationException("Foundry endpoint is not a valid absolute URI. Example: https://<foundry-resource-name>.cognitiveservices.azure.com");
        }

        ValidateEndpoint(endpointUri);

        var apiKey = _options.ApiKey;
        var deployment = _options.DeploymentName;
        if (string.IsNullOrWhiteSpace(deployment))
        {
            throw new InvalidOperationException("AZURE_FOUNDRY_DEPLOYMENT / Foundry:DeploymentName is not configured.");
        }

        var apiVersion = string.IsNullOrWhiteSpace(_options.ApiVersion) ? "2024-05-01-preview" : _options.ApiVersion;
        var requestUri = $"{endpointUri.AbsoluteUri.TrimEnd('/')}/openai/deployments/{deployment}/chat/completions?api-version={apiVersion}";

        var payload = new
        {
            messages = new[]
            {
                new { role = "system", content = "You are a helpful assistant for the Zava Storefront. Keep responses concise and focused on products and pricing." },
                new { role = "user", content = prompt }
            },
            temperature = 0.7,
            max_tokens = 400
        };

        using var request = new HttpRequestMessage(HttpMethod.Post, requestUri)
        {
            Content = new StringContent(JsonSerializer.Serialize(payload, _jsonOptions), Encoding.UTF8, "application/json")
        };

        await AttachAuthenticationAsync(request, apiKey, endpointUri.Host, cancellationToken);

        _logger.LogInformation("Sending chat request to Foundry deployment {Deployment} at {Endpoint}", deployment, endpointUri.Host);

        using var response = await _httpClient.SendAsync(request, cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            var body = await response.Content.ReadAsStringAsync(cancellationToken);
            _logger.LogWarning("Foundry chat call failed with status {StatusCode}: {Body}", response.StatusCode, body);

            var trimmedBody = body?.Length > 2000 ? body[..2000] + "…" : body;
            var hint = response.StatusCode == HttpStatusCode.NotFound
                ? $"Hint: Confirm the endpoint points to your Foundry workspace (e.g., https://<resource>.cognitiveservices.azure.com) and that deployment '{deployment}' exists and is published."
                : null;

            var message = $"Foundry chat request failed: {response.StatusCode} | {trimmedBody}";
            if (!string.IsNullOrWhiteSpace(hint))
            {
                message += $" {hint}";
            }

            throw new InvalidOperationException(message);
        }

        await using var contentStream = await response.Content.ReadAsStreamAsync(cancellationToken);
        var completion = await JsonSerializer.DeserializeAsync<ChatCompletionResponse>(contentStream, _jsonOptions, cancellationToken);
        var reply = completion?.Choices?.FirstOrDefault()?.Message?.Content;

        if (string.IsNullOrWhiteSpace(reply))
        {
            _logger.LogWarning("Foundry response missing content: {@Response}", completion);
            throw new InvalidOperationException("Foundry response did not include a message.");
        }

        return reply.Trim();
    }

    private async Task AttachAuthenticationAsync(HttpRequestMessage request, string? apiKey, string endpointHost, CancellationToken cancellationToken)
    {
        if (!string.IsNullOrWhiteSpace(apiKey))
        {
            _logger.LogDebug("Using API key authentication for Foundry request.");
            request.Headers.Add("api-key", apiKey);
            return;
        }

        // Regional cognitive endpoints require API key; they don't support AAD tokens.
        if (endpointHost.EndsWith("api.cognitive.microsoft.com", StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException("The regional cognitive endpoint requires an API key. To use managed identity, configure a workspace/custom endpoint (e.g., https://<name>.cognitiveservices.azure.com or https://<name>.services.ai.azure.com).");
        }

        // Managed identity / workload identity path
        _logger.LogDebug("Using managed identity authentication for Foundry request.");
        var token = await _credential.GetTokenAsync(new TokenRequestContext(new[] { "https://cognitiveservices.azure.com/.default" }), cancellationToken);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token.Token);
    }

    private async Task<bool> EvaluateSafetyAsync(string prompt, CancellationToken cancellationToken)
    {
        var request = new AnalyzeTextOptions(prompt);

        request.Categories.Add(TextCategory.Violence);
        request.Categories.Add(TextCategory.Sexual);
        request.Categories.Add(TextCategory.Hate);
        request.Categories.Add(TextCategory.SelfHarm);

        var response = await _contentSafetyClient.AnalyzeTextAsync(request, cancellationToken);
        var analyses = response.Value.CategoriesAnalysis;
        var isUnsafe = analyses.Any(a => a.Severity >= 2);

        _logger.LogInformation("Content Safety evaluated prompt. Unsafe={Unsafe}. Details={@Details}", isUnsafe, analyses);

        return !isUnsafe;
    }

    private sealed record ChatCompletionResponse
    {
        public IReadOnlyList<Choice>? Choices { get; init; }

        public sealed record Choice
        {
            public Message? Message { get; init; }
        }

        public sealed record Message
        {
            public string? Role { get; init; }
            public string? Content { get; init; }
        }
    }

    private static void ValidateEndpoint(Uri endpointUri)
    {
        if (!string.Equals(endpointUri.Scheme, Uri.UriSchemeHttps, StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException("Foundry endpoint must use HTTPS.");
        }

        // Accept common Azure OpenAI/Foundry hosts:
        // - *.cognitiveservices.azure.com (Foundry workspace)
        // - *.services.ai.azure.com (new workspace domains)
        // - *.api.cognitive.microsoft.com (regional Azure OpenAI)
        var host = endpointUri.Host.ToLowerInvariant();
        var allowedSuffixes = new[]
        {
            ".cognitiveservices.azure.com",
            ".services.ai.azure.com",
            ".api.cognitive.microsoft.com"
        };

        if (!allowedSuffixes.Any(suffix => host.EndsWith(suffix, StringComparison.Ordinal)))
        {
            throw new InvalidOperationException("Foundry/OpenAI endpoint must be an Azure endpoint (cognitiveservices.azure.com, services.ai.azure.com, or api.cognitive.microsoft.com).");
        }
    }
}
