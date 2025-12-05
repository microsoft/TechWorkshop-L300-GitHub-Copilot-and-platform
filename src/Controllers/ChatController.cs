using Microsoft.AspNetCore.Mvc;
using ZavaStorefront.Services;

namespace ZavaStorefront.Controllers
{
    public class ChatController : Controller
    {
        private readonly ChatService _chatService;
        private readonly ILogger<ChatController> _logger;

        public ChatController(ChatService chatService, ILogger<ChatController> logger)
        {
            _chatService = chatService;
            _logger = logger;
        }

        public IActionResult Index()
        {
            ViewBag.IsConfigured = _chatService.IsConfigured;
            return View();
        }

        [HttpPost]
        public async Task<IActionResult> SendMessage([FromBody] ChatRequest request)
        {
            if (string.IsNullOrWhiteSpace(request?.Message))
            {
                return BadRequest(new { error = "Message cannot be empty" });
            }

            try
            {
                _logger.LogInformation("Processing chat request");
                var response = await _chatService.GetChatResponseAsync(request.Message);
                return Json(new { response });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing chat request");
                return StatusCode(500, new { error = "An error occurred while processing your request. Please try again." });
            }
        }
    }

    public class ChatRequest
    {
        public string Message { get; set; } = string.Empty;
    }
}
