# Project

This lab guides you through a series of practical exercises focused on modernising Zava's business applications and databases by migrating everything to Azure, leveraging GitHub Enterprise, Copilot, and Azure services. Each exercise is designed to deliver hands-on experience in governance, automation, security, AI integration, and observability, ensuring Zava's transition to Azure is robust, secure, and future-ready.

## Quickstart: GitHub Actions Deployment

The workflow at `.github/workflows/quickstart-deploy.yml` builds and deploys the .NET container app to Azure App Service.

### Prerequisites

1. **Azure resources deployed** — Run `azd provision` or deploy the Bicep templates in `/infra` first.
2. **GitHub OIDC federation configured** — Create a federated credential in your Azure AD app registration for GitHub Actions.

### Required GitHub Secrets

Configure these in **Settings > Secrets and variables > Actions > Secrets**:

| Secret | Description |
|--------|-------------|
| `AZURE_CLIENT_ID` | App registration (service principal) client ID |
| `AZURE_TENANT_ID` | Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Target Azure subscription ID |

### Required GitHub Variables

Configure these in **Settings > Secrets and variables > Actions > Variables**:

| Variable | Description | Example |
|----------|-------------|---------|
| `AZURE_RESOURCE_GROUP` | Resource group containing the App Service | `rg-zavastore-dev-westus3` |
| `ACR_NAME` | Azure Container Registry name (without `.azurecr.io`) | `crzavastore7x2k3m` |
| `WEB_APP_NAME` | Azure App Service name | `app-zavastore-dev-7x2k3m` |

> **Tip:** Get these values from your `azd provision` output or the Azure Portal.

### Setting Up OIDC Federation

1. In Azure Portal, go to **Microsoft Entra ID > App registrations**.
2. Create or select an app registration.
3. Under **Certificates & secrets > Federated credentials**, add a credential:
   - **Federated credential scenario**: GitHub Actions deploying Azure resources
   - **Organization**: Your GitHub org/username
   - **Repository**: This repository name
   - **Entity type**: Branch or Environment
   - **Branch**: `main` (or your deployment branch)
4. Grant the app registration **Contributor** and **AcrPush** roles on your subscription or resource group.

For detailed instructions, see [Microsoft Docs: Configure OIDC for GitHub Actions](https://learn.microsoft.com/azure/developer/github/connect-from-azure-openid-connect).

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
