using Azure;
using Azure.AI.OpenAI;
using Azure.Identity;
using OpenAI.Chat;

namespace ZavaStorefront.Services;

/// <summary>
/// Service for communicating with Microsoft Foundry chat completion endpoint.
/// </summary>
public class ChatService : IChatService
{
    private readonly AzureOpenAIClient _client;
    private readonly string _deploymentName;
    private readonly ILogger<ChatService> _logger;
    private readonly int _maxTokens;
    private readonly float _temperature;

    public ChatService(IConfiguration configuration, ILogger<ChatService> logger)
    {
        _logger = logger;

        var endpoint = configuration["AzureFoundry:Endpoint"] 
            ?? throw new InvalidOperationException("AzureFoundry:Endpoint is not configured");
        
        _deploymentName = configuration["AzureFoundry:DeploymentName"] 
            ?? throw new InvalidOperationException("AzureFoundry:DeploymentName is not configured");

        _maxTokens = int.TryParse(configuration["AzureFoundry:MaxTokens"], out var maxTokens) 
            ? maxTokens : 800;
        
        _temperature = float.TryParse(configuration["AzureFoundry:Temperature"], out var temp) 
            ? temp : 0.7f;

        // Try to use API key first (for local dev), fall back to managed identity
        var apiKey = configuration["AzureFoundry:ApiKey"];
        
        if (!string.IsNullOrEmpty(apiKey))
        {
            _logger.LogInformation("Using API key authentication for Azure Foundry");
            _client = new AzureOpenAIClient(new Uri(endpoint), new AzureKeyCredential(apiKey));
        }
        else
        {
            _logger.LogInformation("Using managed identity authentication for Azure Foundry");
            _client = new AzureOpenAIClient(new Uri(endpoint), new DefaultAzureCredential());
        }
    }

    /// <inheritdoc />
    public async Task<string> SendMessageAsync(string userMessage, List<(string role, string content)>? conversationHistory = null)
    {
        try
        {
            _logger.LogInformation("Sending message to Foundry model: {DeploymentName}", _deploymentName);

            var messages = new List<ChatMessage>
            {
                new SystemChatMessage("You are a helpful assistant for Zava Storefront, an e-commerce platform. " +
                    "Help customers with product inquiries and questions. Be friendly, concise, and helpful.")
            };

            // Add conversation history if provided
            if (conversationHistory != null)
            {
                foreach (var (role, messageContent) in conversationHistory)
                {
                    if ("user".Equals(role, StringComparison.CurrentCultureIgnoreCase))
                    {
                        messages.Add(new UserChatMessage(messageContent));
                    }
                    else if ("assistant".Equals(role, StringComparison.CurrentCultureIgnoreCase))
                    {
                        messages.Add(new AssistantChatMessage(messageContent));
                    }
                }
            }

            // Add the current user message
            messages.Add(new UserChatMessage(userMessage));

            var chatClient = _client.GetChatClient(_deploymentName);
            
            var completionOptions = new ChatCompletionOptions
            {
                MaxOutputTokenCount = _maxTokens,
                Temperature = _temperature
            };

            var response = await chatClient.CompleteChatAsync(messages, completionOptions);

            var content = response.Value.Content[0].Text;
            
            _logger.LogInformation("Received response from Foundry model");
            
            return content;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending message to Foundry: {Message}", ex.Message);
            throw new InvalidOperationException("Failed to get response from AI chat service. Please try again later.", ex);
        }
    }
}
