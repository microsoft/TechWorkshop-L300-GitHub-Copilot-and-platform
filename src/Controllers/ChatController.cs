using Microsoft.AspNetCore.Mvc;
using ZavaStorefront.Models;
using ZavaStorefront.Services;

namespace ZavaStorefront.Controllers;

public class ChatController : Controller
{
    private readonly ILogger<ChatController> _logger;
    private readonly FoundryChatService _foundryChatService;

    public ChatController(ILogger<ChatController> logger, FoundryChatService foundryChatService)
    {
        _logger = logger;
        _foundryChatService = foundryChatService;
    }

    [HttpGet]
    public IActionResult Index()
    {
        return View(new ChatViewModel());
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Send(ChatViewModel model, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(model.Prompt))
        {
            model.ErrorMessage = "Please enter a message before sending.";
            return View("Index", model);
        }

        try
        {
            var response = await _foundryChatService.GetResponseAsync(model.Prompt, cancellationToken);
            var newEntry = $"User: {model.Prompt}{Environment.NewLine}Assistant: {response}";
            model.ConversationHistory = string.IsNullOrWhiteSpace(model.ConversationHistory)
                ? newEntry
                : $"{model.ConversationHistory}{Environment.NewLine}{Environment.NewLine}{newEntry}";

            model.Prompt = string.Empty;
            model.ErrorMessage = null;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send chat message to Foundry endpoint.");
            var errorEntry = "Assistant: Sorry, I couldn't reach the Foundry endpoint.";
            model.ConversationHistory = string.IsNullOrWhiteSpace(model.ConversationHistory)
                ? errorEntry
                : $"{model.ConversationHistory}{Environment.NewLine}{Environment.NewLine}{errorEntry}";
            model.ErrorMessage = ex.Message;
        }

        return View("Index", model);
    }
}