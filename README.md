# Project

This lab guides you through a series of practical exercises focused on modernising Zava's business applications and databases by migrating everything to Azure, leveraging GitHub Enterprise, Copilot, and Azure services. Each exercise is designed to deliver hands-on experience in governance, automation, security, AI integration, and observability, ensuring Zava’s transition to Azure is robust, secure, and future-ready.

## GitHub Actions quickstart (container deploy)

This repo includes a minimal GitHub Actions workflow that uses `azd` to provision the infrastructure in `infra/` and deploy the `storefront` service as a container to the App Service it creates: [.github/workflows/azure.yml](.github/workflows/azure.yml).

### Prerequisites

1. Create an Azure service principal with federated credentials for GitHub Actions (OIDC).
2. Ensure the service principal has permission to deploy to your subscription (and to create resources in the target resource group).

### Configure GitHub Secrets

In your GitHub repo, go to **Settings → Secrets and variables → Actions → Secrets** and add:

- `AZURE_CLIENT_ID`: Client ID (appId) of the service principal
- `AZURE_TENANT_ID`: Tenant ID
- `AZURE_SUBSCRIPTION_ID`: Subscription ID

### Optional variables

Edit the workflow file to change:

- `AZURE_ENV_NAME` (default: `dev`)
- `AZURE_LOCATION` (default: `westus3`)

### Run

- Push to `main`, or run the workflow manually from the **Actions** tab.

## assigned the permissions to managed identity

- Cognitive Services OpenAI Contributor
- Cognitive Services Contributor

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
trademarks or logos is subject to and must follow #
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
