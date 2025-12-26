using System.Linq;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using ZavaStorefront.Models;
using ZavaStorefront.Services;

namespace ZavaStorefront.Controllers;

public class ChatController : Controller
{
    private readonly FoundryChatService _chatService;
    private readonly ILogger<ChatController> _logger;

    public ChatController(FoundryChatService chatService, ILogger<ChatController> logger)
    {
        _chatService = chatService;
        _logger = logger;
    }

    [HttpGet]
    public IActionResult Index()
    {
        ViewData["Title"] = "Chat";
        return View();
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> SendMessage([FromBody] ChatMessageRequest request, CancellationToken cancellationToken)
    {
        if (request is null)
        {
            return BadRequest(new { error = "Please enter a question to send." });
        }

        if (!ModelState.IsValid)
        {
            var message = ModelState.Values.SelectMany(v => v.Errors).FirstOrDefault()?.ErrorMessage
                          ?? "Please enter a question to send.";
            return BadRequest(new { error = message });
        }

        var prompt = request.Message!.Trim();
        if (string.IsNullOrEmpty(prompt))
        {
            return BadRequest(new { error = "Please enter a question to send." });
        }

        try
        {
            var reply = await _chatService.GetChatCompletionAsync(prompt, cancellationToken);
            return Ok(new { reply });
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Chat configuration or request failed.");
            return StatusCode(StatusCodes.Status500InternalServerError, new { error = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error while processing chat message.");
            return StatusCode(StatusCodes.Status500InternalServerError, new { error = "Something went wrong while contacting the chat service." });
        }
    }
}
