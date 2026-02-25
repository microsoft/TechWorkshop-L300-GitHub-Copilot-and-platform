using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Options;
using ZavaStorefront.Models;

namespace ZavaStorefront.Services;

public class FoundryChatService
{
    private readonly HttpClient _httpClient;
    private readonly FoundryChatOptions _options;
    private readonly ILogger<FoundryChatService> _logger;

    public FoundryChatService(HttpClient httpClient, IOptions<FoundryChatOptions> options, ILogger<FoundryChatService> logger)
    {
        _httpClient = httpClient;
        _options = options.Value;
        _logger = logger;
    }

    public async Task<string> GetResponseAsync(string prompt, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(_options.Endpoint))
        {
            throw new InvalidOperationException("Foundry endpoint is not configured. Set FoundryChat:Endpoint.");
        }

        if (string.IsNullOrWhiteSpace(_options.ApiKey))
        {
            throw new InvalidOperationException("Foundry API key is not configured. Set FoundryChat:ApiKey.");
        }

        if (string.IsNullOrWhiteSpace(_options.Model))
        {
            throw new InvalidOperationException("Foundry model is not configured. Set FoundryChat:Model.");
        }

        var requestUri = $"{_options.Endpoint.TrimEnd('/')}/models/chat/completions?api-version={_options.ApiVersion}";
        using var request = new HttpRequestMessage(HttpMethod.Post, requestUri);

        if (_options.UseBearerAuth)
        {
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _options.ApiKey);
        }
        else
        {
            request.Headers.Add("api-key", _options.ApiKey);
        }

        var payload = new
        {
            model = _options.Model,
            messages = new[]
            {
                new { role = "user", content = prompt }
            }
        };

        request.Content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");

        using var response = await _httpClient.SendAsync(request, cancellationToken);
        var responseContent = await response.Content.ReadAsStringAsync(cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            _logger.LogWarning("Foundry chat call failed with status {StatusCode}. Response: {ResponseContent}", response.StatusCode, responseContent);
            throw new InvalidOperationException($"Foundry request failed: {(int)response.StatusCode} {response.ReasonPhrase}");
        }

        using var document = JsonDocument.Parse(responseContent);
        var root = document.RootElement;

        if (root.TryGetProperty("choices", out var choices) && choices.GetArrayLength() > 0)
        {
            var message = choices[0].GetProperty("message");
            if (message.TryGetProperty("content", out var contentElement))
            {
                return contentElement.GetString() ?? string.Empty;
            }
        }

        _logger.LogWarning("Foundry chat response did not contain expected content. Response: {ResponseContent}", responseContent);
        throw new InvalidOperationException("Foundry response did not include chat content.");
    }
}