namespace ZavaStorefront.Models;

public class FoundryChatOptions
{
    public const string SectionName = "FoundryChat";

    public string Endpoint { get; set; } = string.Empty;

    public string ApiKey { get; set; } = string.Empty;

    public string Model { get; set; } = "phi-4";

    public string ApiVersion { get; set; } = "2024-05-01-preview";

    public bool UseBearerAuth { get; set; }
}