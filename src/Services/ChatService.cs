using Azure;
using Azure.AI.OpenAI;
using Azure.Identity;
using ZavaStorefront.Models;

namespace ZavaStorefront.Services
{
    public class ChatService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<ChatService> _logger;
        private readonly OpenAIClient _client;
        private readonly string _deploymentName;

        public ChatService(IConfiguration configuration, ILogger<ChatService> logger)
        {
            _configuration = configuration;
            _logger = logger;

            var endpoint = _configuration["AzureOpenAI:Endpoint"] 
                ?? throw new InvalidOperationException("AzureOpenAI:Endpoint configuration is required");
            _deploymentName = _configuration["AzureOpenAI:DeploymentName"] 
                ?? throw new InvalidOperationException("AzureOpenAI:DeploymentName configuration is required");

            // Use DefaultAzureCredential for managed identity authentication
            _client = new OpenAIClient(new Uri(endpoint), new DefaultAzureCredential());
        }

        public async Task<ChatResponse> GetChatResponseAsync(string userMessage)
        {
            try
            {
                _logger.LogInformation("Sending chat request to Azure OpenAI");

                var chatCompletionsOptions = new ChatCompletionsOptions
                {
                    DeploymentName = _deploymentName,
                    Messages =
                    {
                        new ChatRequestSystemMessage("You are a helpful assistant for Zava Storefront. Help customers with questions about products, pricing, and general inquiries. Be friendly and concise."),
                        new ChatRequestUserMessage(userMessage)
                    },
                    MaxTokens = 800,
                    Temperature = 0.7f
                };

                var response = await _client.GetChatCompletionsAsync(chatCompletionsOptions);
                var completion = response.Value;

                if (completion.Choices.Count > 0)
                {
                    var responseContent = completion.Choices[0].Message.Content;
                    _logger.LogInformation("Received chat response successfully");
                    
                    return new ChatResponse
                    {
                        Response = responseContent,
                        Success = true
                    };
                }

                return new ChatResponse
                {
                    Success = false,
                    Error = "No response received from the AI model"
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting chat response from Azure OpenAI");
                return new ChatResponse
                {
                    Success = false,
                    Error = "An error occurred while processing your request. Please try again later."
                };
            }
        }
    }
}
