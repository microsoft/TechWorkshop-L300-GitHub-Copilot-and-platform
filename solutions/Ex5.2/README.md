# Project

This lab guides you through a series of practical exercises focused on modernising Zava's business applications and databases by migrating everything to Azure, leveraging GitHub Enterprise, Copilot, and Azure services. Each exercise is designed to deliver hands-on experience in governance, automation, security, AI integration, and observability, ensuring Zava's transition to Azure is robust, secure, and future-ready.

## ZavaStorefront Application

ZavaStorefront is a .NET 10 web application that demonstrates modern cloud-native development practices on Azure. The application is containerized and deployed to Azure App Service using Azure Container Registry, with integrated monitoring via Application Insights and AI capabilities through Azure Foundry.

### Quick Start

#### Prerequisites
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) (v2.50.0+)
- [Azure Developer CLI (azd)](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd) (recommended)
- Azure subscription with appropriate permissions

#### Deploy Infrastructure and Application

Using Azure Developer CLI (recommended):

```bash
# Login to Azure
azd auth login

# Initialize the project (first time only)
azd init

# Provision infrastructure and deploy application
azd up
```

For detailed deployment instructions and alternative methods, see the [Infrastructure README](infra/README.md).

### Repository Structure

```
.
├── .github/
│   └── workflows/         # GitHub Actions workflows
├── infra/                 # Azure infrastructure (Bicep templates)
│   ├── modules/           # Reusable Bicep modules
│   ├── main.bicep         # Main infrastructure template
│   └── README.md          # Detailed infrastructure documentation
├── src/                   # ZavaStorefront .NET application
├── Dockerfile             # Container image definition
└── azure.yaml             # Azure Developer CLI configuration
```

### Infrastructure Overview

The application is deployed to Azure using Infrastructure as Code (Bicep templates). Key components:

- **Azure Container Registry**: Stores container images
- **App Service (Linux)**: Hosts the containerized application
- **Application Insights**: Application monitoring and telemetry
- **Azure Foundry**: GPT-5-mini and Phi-4 for AI capabilities

All resources are provisioned in the **westus3** region for optimal performance and AI model availability.

**Security Features:**
- System-assigned managed identity for secure ACR access
- No password-based authentication (Azure RBAC with AcrPull role)
- HTTPS-only endpoints
- Application Insights for security monitoring

**Cost Optimization:**
- Dev environment uses minimal-cost SKUs (Basic ACR, B1 App Service)
- Estimated monthly cost: ~$20-30 for dev environment
- Resources can be stopped when not in use

For complete infrastructure documentation, deployment options, and troubleshooting, see [infra/README.md](infra/README.md).

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
