using Microsoft.AspNetCore.Mvc;
using ZavaStorefront.Services;

namespace ZavaStorefront.Controllers;

/// <summary>
/// Controller for handling chat functionality with AI assistant.
/// </summary>
public class ChatController : Controller
{
    private readonly IChatService _chatService;
    private readonly ILogger<ChatController> _logger;

    public ChatController(IChatService chatService, ILogger<ChatController> logger)
    {
        _chatService = chatService;
        _logger = logger;
    }

    /// <summary>
    /// Displays the chat page.
    /// </summary>
    public IActionResult Index()
    {
        return View();
    }

    /// <summary>
    /// Sends a message to the AI chat service and returns the response.
    /// </summary>
    /// <param name="message">The user's message.</param>
    /// <param name="history">Optional conversation history.</param>
    [HttpPost]
    public async Task<IActionResult> SendMessage([FromBody] ChatRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Message))
        {
            return BadRequest(new { error = "Message cannot be empty." });
        }

        if (request.Message.Length > 500)
        {
            return BadRequest(new { error = "Message is too long. Maximum 500 characters allowed." });
        }

        try
        {
            _logger.LogInformation("Processing chat message");

            var response = await _chatService.SendMessageAsync(
                request.Message, 
                request.History
            );

            return Json(new { response });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing chat message");
            return StatusCode(500, new { error = "An error occurred while processing your message. Please try again." });
        }
    }
}

/// <summary>
/// Request model for chat messages.
/// </summary>
public class ChatRequest
{
    public string Message { get; set; } = string.Empty;
    public List<(string role, string content)>? History { get; set; }
}
