using System.ComponentModel.DataAnnotations;

namespace ZavaStorefront.Models;

public class ChatMessageRequest
{
    [Required]
    [StringLength(1000, ErrorMessage = "Messages must be 1000 characters or fewer.")]
    public string? Message { get; set; }
}
