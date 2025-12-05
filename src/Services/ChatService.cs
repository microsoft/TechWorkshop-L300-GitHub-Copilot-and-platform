using Azure;
using Azure.AI.OpenAI;
using Azure.Identity;
using OpenAI.Chat;

namespace ZavaStorefront.Services
{
    public class ChatService
    {
        private readonly ChatClient? _chatClient;
        private readonly ILogger<ChatService> _logger;
        private readonly bool _isConfigured;

        public ChatService(IConfiguration configuration, ILogger<ChatService> logger)
        {
            _logger = logger;
            
            var endpoint = configuration["AzureAI:Endpoint"];
            var deploymentName = configuration["AzureAI:DeploymentName"] ?? "gpt-4o-mini";

            if (string.IsNullOrEmpty(endpoint))
            {
                _logger.LogWarning("AzureAI:Endpoint is not configured. Chat functionality will be disabled.");
                _isConfigured = false;
                return;
            }

            try
            {
                // Use managed identity for authentication (no API keys)
                var credential = new DefaultAzureCredential();
                var client = new AzureOpenAIClient(new Uri(endpoint), credential);
                _chatClient = client.GetChatClient(deploymentName);
                _isConfigured = true;
                _logger.LogInformation("ChatService initialized with endpoint: {Endpoint}, deployment: {Deployment}", endpoint, deploymentName);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to initialize ChatService");
                _isConfigured = false;
            }
        }

        public bool IsConfigured => _isConfigured;

        public async Task<string> GetChatResponseAsync(string userMessage)
        {
            if (!_isConfigured || _chatClient == null)
            {
                return "Chat service is not configured. Please configure the AzureAI settings.";
            }

            try
            {
                _logger.LogInformation("Sending chat request to AI model");

                var messages = new List<ChatMessage>
                {
                    new SystemChatMessage("You are a helpful assistant for Zava Storefront, an online retail shop. Help customers with product inquiries, shopping assistance, and general questions. Be friendly and concise."),
                    new UserChatMessage(userMessage)
                };

                var response = await _chatClient.CompleteChatAsync(messages);
                
                var responseText = response.Value.Content[0].Text;
                _logger.LogInformation("Received response from AI model");
                
                return responseText;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting chat response from AI model");
                throw;
            }
        }
    }
}
