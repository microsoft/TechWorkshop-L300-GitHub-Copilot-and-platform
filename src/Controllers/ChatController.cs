using Azure.AI.ContentSafety;
using Azure.Core;
using Azure.Identity;
using Microsoft.AspNetCore.Mvc;
using System.Linq;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace ZavaStorefront.Controllers
{
    public class ChatController : Controller
    {
        private readonly ILogger<ChatController> _logger;
        private readonly IConfiguration _configuration;
        private readonly IHttpClientFactory _httpClientFactory;

        public ChatController(ILogger<ChatController> logger, IConfiguration configuration, IHttpClientFactory httpClientFactory)
        {
            _logger = logger;
            _configuration = configuration;
            _httpClientFactory = httpClientFactory;
        }

        public IActionResult Index()
        {
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> SendMessage([FromBody] ChatRequest request)
        {
            if (string.IsNullOrWhiteSpace(request?.Message))
            {
                return BadRequest("Message cannot be empty.");
            }

            var endpoint = _configuration["AzureAI:Endpoint"];
            if (string.IsNullOrWhiteSpace(endpoint))
            {
                return StatusCode(503, "AI endpoint is not configured.");
            }

            // Content Safety check before forwarding to the model
            if (!await IsContentSafeAsync(request.Message))
            {
                return Ok(new { reply = "I'm sorry, but I can't respond to that message. Please keep the conversation respectful and on-topic." });
            }

            // Try Phi-4 first, fall back to gpt-4o
            var deploymentName = _configuration["AzureAI:DeploymentName"] ?? "phi-4";
            var fallbackDeploymentName = _configuration["AzureAI:FallbackDeploymentName"] ?? "gpt-4o";

            var result = await TrySendToDeployment(endpoint, deploymentName, request.Message);
            if (result == null)
            {
                _logger.LogWarning("Phi-4 deployment failed, falling back to {Fallback}", fallbackDeploymentName);
                result = await TrySendToDeployment(endpoint, fallbackDeploymentName, request.Message);
            }

            if (result == null)
            {
                return StatusCode(502, "Could not get a response from the AI service.");
            }

            return Ok(new { reply = result });
        }

        /// <summary>
        /// Evaluates text against Azure AI Content Safety.
        /// Returns true if safe, false if any category scores severity >= 2.
        /// Note: jailbreak detection requires Content Safety API version 2024-02-15-preview
        /// or later; the 1.0.0 GA SDK covers hate, violence, sexual, and self-harm.
        /// </summary>
        private async Task<bool> IsContentSafeAsync(string text)
        {
            var safetyEndpoint = _configuration["ContentSafety:Endpoint"];
            if (string.IsNullOrWhiteSpace(safetyEndpoint))
            {
                _logger.LogWarning("ContentSafety:Endpoint not configured — skipping safety check.");
                return true;
            }

            try
            {
                var client = new ContentSafetyClient(new Uri(safetyEndpoint), new DefaultAzureCredential());

                var analyzeOptions = new AnalyzeTextOptions(text);
                var response = await client.AnalyzeTextAsync(analyzeOptions);

                foreach (var item in response.Value.CategoriesAnalysis)
                {
                    if (item.Severity >= 2)
                    {
                        _logger.LogWarning("Content Safety blocked message. Category={Category} Severity={Severity}", item.Category, item.Severity);
                        return false;
                    }
                }

                _logger.LogInformation("Content Safety passed. Categories={Categories}",
                    string.Join(", ", response.Value.CategoriesAnalysis.Select(c => $"{c.Category}:{c.Severity}")));
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Content Safety check failed — allowing request to proceed.");
                return true; // fail-open to avoid breaking chat if Safety service is unavailable
            }
        }

        private async Task<string?> TrySendToDeployment(string baseEndpoint, string deploymentName, string userMessage)
        {
            try
            {
                var client = _httpClientFactory.CreateClient("AzureAI");

                // Identity-only: DefaultAzureCredential uses az login locally, Managed Identity in Azure
                var credential = new DefaultAzureCredential();
                var tokenRequest = new TokenRequestContext(new[] { "https://cognitiveservices.azure.com/.default" });
                var token = await credential.GetTokenAsync(tokenRequest);
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token.Token);

                // Azure AI Services OpenAI-compatible endpoint
                var url = $"{baseEndpoint.TrimEnd('/')}/openai/deployments/{deploymentName}/chat/completions?api-version=2024-05-01-preview";

                var payload = new
                {
                    messages = new[]
                    {
                        new { role = "system", content = "You are a helpful assistant for Zava Storefront, a technology products store. Help customers with product information and recommendations. Be concise and friendly." },
                        new { role = "user", content = userMessage }
                    },
                    max_tokens = 500,
                    temperature = 0.7
                };

                var json = JsonSerializer.Serialize(payload);
                var content = new StringContent(json, Encoding.UTF8, "application/json");

                var response = await client.PostAsync(url, content);

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogWarning("Deployment {Deployment} returned {StatusCode}", deploymentName, response.StatusCode);
                    return null;
                }

                var responseBody = await response.Content.ReadAsStringAsync();
                var responseJson = JsonDocument.Parse(responseBody);
                var reply = responseJson.RootElement
                    .GetProperty("choices")[0]
                    .GetProperty("message")
                    .GetProperty("content")
                    .GetString();

                _logger.LogInformation("Chat response received from deployment {Deployment}", deploymentName);
                return reply;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error calling deployment {Deployment}", deploymentName);
                return null;
            }
        }
    }

    public class ChatRequest
    {
        public string? Message { get; set; }
    }
}
