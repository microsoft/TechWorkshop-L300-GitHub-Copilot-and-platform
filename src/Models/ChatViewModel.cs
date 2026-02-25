using System.ComponentModel.DataAnnotations;

namespace ZavaStorefront.Models;

public class ChatViewModel
{
    [Required]
    public string Prompt { get; set; } = string.Empty;

    public string ConversationHistory { get; set; } = string.Empty;

    public string? ErrorMessage { get; set; }
}