using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Options;
using ZavaStorefront.Models;

namespace ZavaStorefront.Services;

public class FoundryChatService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<FoundryChatService> _logger;
    private readonly FoundryOptions _options;
    private static readonly JsonSerializerOptions _jsonOptions = new(JsonSerializerDefaults.Web);

    public FoundryChatService(HttpClient httpClient, IOptions<FoundryOptions> options, ILogger<FoundryChatService> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
        _options = options.Value;
    }

    public async Task<string> GetChatCompletionAsync(string prompt, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(prompt))
        {
            throw new ArgumentException("Prompt cannot be empty.", nameof(prompt));
        }

        var endpoint = _options.Endpoint?.TrimEnd('/') ?? throw new InvalidOperationException("AZURE_FOUNDRY_ENDPOINT / Foundry:Endpoint is not configured.");
        var apiKey = _options.ApiKey ?? throw new InvalidOperationException("AZURE_FOUNDRY_API_KEY / Foundry:ApiKey is not configured.");
        var deployment = _options.DeploymentName;
        if (string.IsNullOrWhiteSpace(deployment))
        {
            throw new InvalidOperationException("AZURE_FOUNDRY_DEPLOYMENT / Foundry:DeploymentName is not configured.");
        }

        var apiVersion = string.IsNullOrWhiteSpace(_options.ApiVersion) ? "2024-05-01-preview" : _options.ApiVersion;
        var requestUri = $"{endpoint}/openai/deployments/{deployment}/chat/completions?api-version={apiVersion}";

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

        if (!request.Headers.Contains("api-key"))
        {
            request.Headers.Add("api-key", apiKey);
        }

        _logger.LogInformation("Sending chat request to Foundry deployment {Deployment}", deployment);

        using var response = await _httpClient.SendAsync(request, cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            var body = await response.Content.ReadAsStringAsync(cancellationToken);
            _logger.LogWarning("Foundry chat call failed with status {StatusCode}: {Body}", response.StatusCode, body);
            throw new InvalidOperationException($"Foundry chat request failed: {response.StatusCode}");
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
}
