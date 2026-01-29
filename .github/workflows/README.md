# GitHub Actions Workflow Configuration

This workflow builds and deploys the ZavaStorefront .NET application as a container to Azure App Service.

## Prerequisites

1. Infrastructure deployed via `azd up` or the Bicep templates in `/infra`
2. A GitHub App or Service Principal with federated credentials for OIDC authentication

## Configure GitHub Secrets

Add these **secrets** in your repository (Settings → Secrets and variables → Actions → Secrets):

| Secret | Description |
|--------|-------------|
| `AZURE_CLIENT_ID` | The Application (client) ID of your Azure AD app registration |
| `AZURE_TENANT_ID` | Your Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Your Azure subscription ID |

## Configure GitHub Variables

Add these **variables** in your repository (Settings → Secrets and variables → Actions → Variables):

| Variable | Description | Example |
|----------|-------------|---------|
| `AZURE_WEBAPP_NAME` | Name of your Azure Web App | `app-abc123xyz` |
| `ACR_LOGIN_SERVER` | ACR login server URL | `cracr123xyz.azurecr.io` |

> **Tip:** Run `azd env get-values` to retrieve these values after deploying infrastructure.

## Setting Up OIDC Authentication

1. Create an Azure AD App Registration
2. Add a federated credential for GitHub Actions:
   - Organization: `<your-github-org>`
   - Repository: `<your-repo-name>`
   - Entity type: `Branch`
   - Branch: `main`
3. Assign the app registration the following roles on your resource group:
   - `Contributor` (for App Service deployments)
   - `AcrPush` (on the Container Registry)
