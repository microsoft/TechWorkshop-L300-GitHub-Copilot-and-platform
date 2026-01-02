# Add Chat Functionality with Microsoft Foundry Integration

## Overview
Add a new chat feature to the ZavaStorefront application that integrates with the Microsoft Foundry Phi-4 model endpoint. This will provide users with an AI-powered assistant to help with product inquiries and general questions.

## Business Value
- **Enhanced Customer Experience**: Provide instant AI-powered assistance to customers
- **Product Discovery**: Help users find products through conversational interface
- **Modern Experience**: Demonstrate AI capabilities using Microsoft Foundry
- **Cost Effective**: Leverage already deployed Phi-4 model infrastructure

## Feature Requirements

### User Interface
- [ ] Create a new "Chat" page accessible from the main navigation
- [ ] Implement a chat interface with:
  - Text input field for user messages
  - Send button to submit messages
  - Text area displaying conversation history
  - Clear/reset conversation button
  - Loading indicator during API calls
  - Error message display for failed requests

### Backend Integration
- [ ] Create a new controller action to handle chat requests
- [ ] Implement service layer to communicate with Microsoft Foundry endpoint
- [ ] Configure Phi-4 model endpoint from Azure Foundry deployment
- [ ] Handle API authentication using Azure credentials
- [ ] Implement proper error handling and logging

### Configuration
- [ ] Add Foundry endpoint URL to app configuration
- [ ] Add Foundry API key to app settings (use Azure Key Vault or managed identity)
- [ ] Configure model parameters (temperature, max tokens, etc.)
- [ ] Add feature flag to enable/disable chat functionality

## Technical Specifications

### New Files to Create

#### 1. **Chat Controller** (`Controllers/ChatController.cs`)
```csharp
- ChatController with Index action for page rendering
- SendMessage action (POST) to handle chat submissions
- Returns JSON response with AI-generated content
```

#### 2. **Chat Service** (`Services/ChatService.cs`)
```csharp
- Interface: IChatService
- Implementation: ChatService
- Methods:
  - Task<string> SendMessageAsync(string userMessage)
  - Configuration for Foundry endpoint and model
```

#### 3. **Chat View** (`Views/Chat/Index.cshtml`)
```html
- Chat interface UI
- Text area for conversation history
- Input field and send button
- JavaScript for AJAX calls to backend
- Bootstrap styling for responsive design
```

#### 4. **Configuration** (`appsettings.json`)
```json
{
  "AzureFoundry": {
    "Endpoint": "https://<your-foundry-resource>.openai.azure.com/",
    "DeploymentName": "Phi-4",
    "ApiVersion": "2024-10-01-preview",
    "MaxTokens": 800,
    "Temperature": 0.7
  }
}
```

### API Integration Details

**Microsoft Foundry Chat Completion API:**
- Endpoint: `{foundry-endpoint}/openai/deployments/{deployment-name}/chat/completions?api-version={api-version}`
- Method: POST
- Authentication: API Key or Managed Identity
- Request Body:
```json
{
  "messages": [
    {
      "role": "system",
      "content": "You are a helpful assistant for Zava Storefront, an e-commerce platform. Help customers with product inquiries and questions."
    },
    {
      "role": "user",
      "content": "User's message here"
    }
  ],
  "max_tokens": 800,
  "temperature": 0.7
}
```

### Dependencies to Add

Update `ZavaStorefront.csproj`:
```xml
<PackageReference Include="Azure.AI.OpenAI" Version="2.1.0" />
<PackageReference Include="Azure.Identity" Version="1.13.1" />
```

## Implementation Steps

### Phase 1: Backend Setup
1. **Add NuGet Packages**
   ```bash
   cd src
   dotnet add package Azure.AI.OpenAI --version 2.1.0
   dotnet add package Azure.Identity --version 1.13.1
   ```

2. **Update Configuration**
   - Add Foundry settings to `appsettings.json`
   - Add Foundry settings to `appsettings.Development.json` for local testing

3. **Create Chat Service**
   - Create `Services/IChatService.cs` interface
   - Create `Services/ChatService.cs` implementation
   - Register service in `Program.cs` DI container

4. **Create Chat Controller**
   - Create `Controllers/ChatController.cs`
   - Add Index action for GET requests
   - Add SendMessage action for POST requests

### Phase 2: Frontend Implementation
5. **Create Chat View**
   - Create `Views/Chat/Index.cshtml`
   - Add chat interface HTML structure
   - Include Bootstrap styling

6. **Add JavaScript Functionality**
   - Create or update `wwwroot/js/chat.js`
   - Implement AJAX calls to SendMessage endpoint
   - Handle loading states and error messages
   - Update conversation display

7. **Update Navigation**
   - Add "Chat" link to `Views/Shared/_Layout.cshtml`
   - Add appropriate icon (e.g., chat bubble)

### Phase 3: Configuration & Security
8. **Configure Azure Resources**
   - Retrieve Foundry endpoint URL from Azure Portal
   - Configure managed identity access (recommended) or API key
   - Test connectivity to Phi-4 deployment

9. **Add Security Measures**
   - Implement rate limiting to prevent abuse
   - Add input validation and sanitization
   - Implement request logging for monitoring

### Phase 4: Testing
10. **Test Locally**
    - Test chat interface renders correctly
    - Test message submission and response display
    - Test error handling (invalid input, API failures)
    - Test conversation flow with multiple messages

11. **Test Deployment**
    - Deploy to Azure App Service
    - Verify managed identity permissions
    - Test production endpoint connectivity
    - Verify error logging in Application Insights

## UI/UX Design

### Chat Page Layout
```
┌─────────────────────────────────────────┐
│  Zava Storefront - Chat Assistant      │
├─────────────────────────────────────────┤
│                                         │
│  ┌───────────────────────────────────┐ │
│  │  Conversation History             │ │
│  │                                   │ │
│  │  User: Hello!                     │ │
│  │  AI: Hi! How can I help you?      │ │
│  │                                   │ │
│  │  [Scroll area]                    │ │
│  └───────────────────────────────────┘ │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │  Type your message...             │ │
│  └───────────────────────────────────┘ │
│  [Send]  [Clear]                        │
│                                         │
└─────────────────────────────────────────┘
```

## Acceptance Criteria

### Functionality
- ✅ Chat page is accessible from main navigation
- ✅ Users can type messages and submit them
- ✅ Messages are sent to Microsoft Foundry Phi-4 endpoint
- ✅ AI responses are displayed in the conversation area
- ✅ Conversation history is maintained during session
- ✅ Clear button resets the conversation
- ✅ Loading indicator shows during API calls
- ✅ Error messages display when API calls fail

### Technical
- ✅ Uses Azure.AI.OpenAI SDK for API integration
- ✅ Properly configured to use Phi-4 deployment
- ✅ Implements proper error handling and logging
- ✅ Uses managed identity for authentication (production)
- ✅ Configuration is externalized (appsettings.json)
- ✅ Service is registered in DI container
- ✅ Code follows existing project patterns and conventions

### Quality
- ✅ Responsive design works on mobile and desktop
- ✅ Input validation prevents empty messages
- ✅ Proper error messages for users
- ✅ Application Insights logs chat interactions
- ✅ No sensitive data (API keys) in source code
- ✅ Code is documented with XML comments

## Security Considerations

1. **Authentication**
   - Use Azure Managed Identity in production
   - Store API keys in Azure Key Vault (if managed identity not available)
   - Never commit API keys to source control

2. **Input Validation**
   - Sanitize user input to prevent injection attacks
   - Limit message length (e.g., 500 characters)
   - Implement rate limiting per session/IP

3. **Output Handling**
   - Encode AI responses to prevent XSS attacks
   - Validate response format from API
   - Handle unexpected or malformed responses gracefully

4. **Monitoring**
   - Log all chat interactions (without sensitive data)
   - Monitor API usage and costs
   - Set up alerts for unusual activity or errors

## Configuration Example

### Local Development (`appsettings.Development.json`)
```json
{
  "AzureFoundry": {
    "Endpoint": "https://oai-zavastore-dev-westus3.openai.azure.com/",
    "DeploymentName": "Phi-4",
    "ApiKey": "<your-api-key-here>",
    "ApiVersion": "2024-10-01-preview",
    "MaxTokens": 800,
    "Temperature": 0.7
  }
}
```

### Production (`Azure App Service Configuration`)
- Use Application Settings in Azure Portal
- Enable Managed Identity on App Service
- Grant "Cognitive Services OpenAI User" role to the managed identity

## Testing Checklist

### Unit Tests
- [ ] ChatService correctly formats API requests
- [ ] ChatService handles API errors gracefully
- [ ] ChatController validates input properly
- [ ] ChatController returns correct response format

### Integration Tests
- [ ] End-to-end message flow works correctly
- [ ] API authentication succeeds
- [ ] Error handling works for various failure scenarios
- [ ] Conversation state is maintained correctly

### Manual Tests
- [ ] UI renders correctly on desktop browsers
- [ ] UI renders correctly on mobile devices
- [ ] Send button enables/disables appropriately
- [ ] Loading indicator shows during API calls
- [ ] Error messages display correctly
- [ ] Clear button resets conversation
- [ ] Multiple messages can be sent in sequence
- [ ] Navigation to/from chat page works

## Success Metrics

- Chat feature successfully integrates with Phi-4 model
- Users can have multi-turn conversations
- Average response time < 3 seconds
- Error rate < 1%
- No security vulnerabilities introduced

## Priority
**Medium** - Feature enhancement that demonstrates AI capabilities but not critical for core e-commerce functionality

## Estimated Effort
**4-8 hours** - Moderate complexity involving backend API integration, frontend development, and configuration

## Labels
`enhancement`, `feature`, `ai`, `chat`, `microsoft-foundry`

## References
- [Azure OpenAI Service REST API](https://learn.microsoft.com/en-us/azure/ai-services/openai/reference)
- [Azure.AI.OpenAI SDK Documentation](https://learn.microsoft.com/en-us/dotnet/api/overview/azure/ai.openai-readme)
- [Azure Managed Identity](https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview)
- [ASP.NET Core Dependency Injection](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/dependency-injection)
- [Phi-4 Model Documentation](https://azure.microsoft.com/en-us/products/ai-model-catalog)

## Related Issues
- Depends on: Microsoft Foundry infrastructure (already deployed)
- Blocks: Future enhancements like chat history persistence, multi-user support

## Notes
- Consider session-based conversation history (no database persistence initially)
- Future enhancement: Add product recommendations based on chat context
- Future enhancement: Persist chat history to database
- Future enhancement: Add streaming responses for better UX
