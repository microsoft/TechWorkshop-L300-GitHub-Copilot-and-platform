# Project

This lab guides you through a series of practical exercises focused on modernising Zava's business applications and databases by migrating everything to Azure, leveraging GitHub Enterprise, Copilot, and Azure services. Each exercise is designed to deliver hands-on experience in governance, automation, security, AI integration, and observability, ensuring Zava’s transition to Azure is robust, secure, and future-ready.
## ZavaStorefront Application

The ZavaStorefront is a .NET 6 ASP.NET Core MVC e-commerce application that demonstrates modern cloud-native development practices. The application includes:

- **Product Catalog**: Browse and search products
- **Shopping Cart**: Add, update, and remove items
- **Containerized Deployment**: Runs as a Docker container
- **Azure Integration**: Application Insights monitoring and Azure OpenAI capabilities

## Quick Start

### Prerequisites

- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli) (v2.50.0+)
- [Azure Developer CLI (azd)](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd) (v1.5.0+)
- Active Azure subscription
- .NET 6 SDK (for local development)

### Deploy to Azure

The application uses Azure Developer CLI for simplified infrastructure provisioning and deployment:

```bash
# 1. Authenticate with Azure
azd auth login

# 2. Initialize environment
azd env new zava-dev
azd env set AZURE_LOCATION westus3

# 3. Provision infrastructure and deploy
azd up
```

This will:
- Create a resource group in westus3
- Provision Azure Container Registry, App Service, Application Insights, Log Analytics, and Azure OpenAI
- Build and push the container image
- Deploy the application

**Access your application**: The deployment outputs the web app URL.

### Local Development

```bash
cd src
dotnet restore
dotnet run
```

Navigate to `http://localhost:5256` or `https://localhost:7060`

### Infrastructure Details

All infrastructure is defined as code using Bicep templates. See [infra/README.md](infra/README.md) for:
- Architecture overview
- Detailed deployment instructions
- Configuration options
- Troubleshooting guide
- Cost estimates
## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
