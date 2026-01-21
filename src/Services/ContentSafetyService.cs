using System;
using System.Threading.Tasks;
using Azure;
using Azure.AI.ContentSafety;
using Azure.AI.ContentSafety.Models;
using Microsoft.Extensions.Logging;

namespace ZavaStorefront.Services
{
    public class ContentSafetyService
    {
        private readonly ContentSafetyClient _client;
        private readonly ILogger<ContentSafetyService> _logger;
        public ContentSafetyService(string endpoint, string key, ILogger<ContentSafetyService> logger)
        {
            _client = new ContentSafetyClient(new Uri(endpoint), new AzureKeyCredential(key));
            _logger = logger;
        }

        public async Task<(bool isSafe, string log)> EvaluateTextAsync(string text)
        {
            var request = new AnalyzeTextOptions(text)
            {
                Categories = { TextCategory.Violence, TextCategory.Sexual, TextCategory.Hate, TextCategory.SelfHarm, TextCategory.Jailbreak }
            };
            var response = await _client.AnalyzeTextAsync(request);
            bool isSafe = true;
            string log = "Content Safety Results: ";
            foreach (var result in response.Value.CategoriesAnalysis)
            {
                log += $"{result.Category}: {result.Severity}; ";
                if (result.Severity >= 2)
                {
                    isSafe = false;
                }
            }
            _logger.LogInformation(log);
            return (isSafe, log);
        }
    }
}
