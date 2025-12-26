namespace ZavaStorefront.Models;

public class FoundryOptions
{
    public string? Endpoint { get; set; }
    public string? ApiKey { get; set; }
    public string DeploymentName { get; set; } = "phi-4-mini-instruct";
    public string ApiVersion { get; set; } = "2024-05-01-preview";
}
