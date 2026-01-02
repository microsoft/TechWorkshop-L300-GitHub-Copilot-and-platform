namespace ZavaStorefront.Services;

/// <summary>
/// Interface for chat service that communicates with Microsoft Foundry.
/// </summary>
public interface IChatService
{
    /// <summary>
    /// Sends a message to the AI chat model and returns the response.
    /// </summary>
    /// <param name="userMessage">The message from the user.</param>
    /// <param name="conversationHistory">Optional conversation history for context.</param>
    /// <returns>The AI-generated response.</returns>
    Task<string> SendMessageAsync(string userMessage, List<(string role, string content)>? conversationHistory = null);
}
