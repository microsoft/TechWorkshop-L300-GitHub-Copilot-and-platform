# GitHub Actions Deployment Setup

This workflow builds the .NET app as a container and deploys it to Azure App Service.

## Prerequisites

1. Deploy the infrastructure using `azd up` from the project root
2. Create a Microsoft Entra ID app registration for GitHub Actions (federated credentials)

## Configure GitHub Secrets

Go to **Settings > Secrets and variables > Actions > Secrets** and add:

| Secret | Description |
|--------|-------------|
| `AZURE_CLIENT_ID` | Application (client) ID of the app registration |
| `AZURE_TENANT_ID` | Directory (tenant) ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |

## Configure GitHub Variables

Go to **Settings > Secrets and variables > Actions > Variables** and add:

| Variable | Description | Example |
|----------|-------------|---------|
| `AZURE_WEBAPP_NAME` | Name of your App Service | `app-abc123xyz` |
| `ACR_LOGIN_SERVER` | ACR login server (without https://) | `crabc123xyz.azurecr.io` |

## Setting up Federated Credentials

1. In Azure Portal, go to **Microsoft Entra ID > App registrations**
2. Create a new registration or use an existing one
3. Go to **Certificates & secrets > Federated credentials > Add credential**
4. Select **GitHub Actions deploying Azure resources**
5. Enter your organization, repository, and entity type (Branch: `main`)
6. Grant the app registration **Contributor** role on your resource group and **AcrPush** role on the container registry
