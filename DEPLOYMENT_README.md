# GitHub Actions Deployment Setup

This repository contains a GitHub Actions workflow that automatically builds and deploys your .NET application as a container to Azure App Service.

## Prerequisites

Before running the workflow, you need to configure the following GitHub secrets and variables.

## Required GitHub Secrets

Configure these secrets in your repository settings (`Settings` → `Secrets and variables` → `Actions` → `New repository secret`):

| Secret Name | Description | How to Get |
|------------|-------------|------------|
| `AZURE_CLIENT_ID` | Azure App Registration Client ID | Create an app registration in Azure AD and use its Application (client) ID |
| `AZURE_TENANT_ID` | Azure Active Directory Tenant ID | Found in Azure Portal → Azure Active Directory → Overview |
| `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID | Found in Azure Portal → Subscriptions |

## Required GitHub Variables

Configure these variables in your repository settings (`Settings` → `Secrets and variables` → `Actions` → `Variables` tab → `New repository variable`):

| Variable Name | Description | Example Value |
|--------------|-------------|---------------|
| `AZURE_CONTAINER_REGISTRY_NAME` | Name of your Azure Container Registry (without .azurecr.io) | `crzavastoredeva1b2c3d4` |
| `AZURE_APP_SERVICE_NAME` | Name of your Azure App Service | `app-zavastore-dev-westus3` |
| `AZURE_RESOURCE_GROUP` | Name of your Azure Resource Group | `rg-zavastore-dev-westus3` |

## Setting Up Azure Authentication with OIDC

To enable GitHub Actions to authenticate to Azure, follow these steps:

### 1. Create an Azure AD App Registration

```bash
az ad app create --display-name "GitHub-Actions-ZavaStorefront"
```

Note the `appId` from the output - this becomes your `AZURE_CLIENT_ID`.

### 2. Create a Service Principal

```bash
az ad sp create --id <APP_ID>
```

### 3. Configure Federated Credentials for GitHub

Replace `<APP_ID>`, `<GITHUB_ORG>`, and `<GITHUB_REPO>` with your values:

```bash
az ad app federated-credential create \
  --id <APP_ID> \
  --parameters '{
    "name": "github-actions-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:<GITHUB_ORG>/<GITHUB_REPO>:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### 4. Assign Contributor Role

```bash
az role assignment create \
  --assignee <APP_ID> \
  --role Contributor \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP_NAME>
```

### 5. Assign AcrPush Role (for ACR access)

```bash
az role assignment create \
  --assignee <APP_ID> \
  --role AcrPush \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP_NAME>/providers/Microsoft.ContainerRegistry/registries/<ACR_NAME>
```

## Finding Your Resource Names

If you've already deployed your infrastructure using the Bicep templates in the `infra` folder, you can find your resource names:

```bash
# List all resources in your resource group
az resource list --resource-group <RESOURCE_GROUP_NAME> --output table

# Get ACR name
az acr list --resource-group <RESOURCE_GROUP_NAME> --query "[0].name" -o tsv

# Get App Service name
az webapp list --resource-group <RESOURCE_GROUP_NAME> --query "[0].name" -o tsv
```

## Workflow Behavior

- **Trigger**: Automatically runs on push to `main` branch, or manually via workflow dispatch
- **Build**: Builds the Docker image directly in Azure Container Registry (no local Docker needed)
- **Tag**: Tags image with both commit SHA and `latest`
- **Deploy**: Updates App Service to use the newly built container image
- **Restart**: Restarts the App Service to pull the new image

## Verifying Deployment

After the workflow completes, verify your deployment:

```bash
# Check App Service status
az webapp show \
  --name <APP_SERVICE_NAME> \
  --resource-group <RESOURCE_GROUP_NAME> \
  --query "state" -o tsv

# View App Service URL
az webapp show \
  --name <APP_SERVICE_NAME> \
  --resource-group <RESOURCE_GROUP_NAME> \
  --query "defaultHostName" -o tsv
```

## Troubleshooting

If the workflow fails, check:

1. All secrets and variables are configured correctly in GitHub
2. The service principal has the necessary permissions (Contributor + AcrPush)
3. Your infrastructure has been deployed via `azd up` or Bicep templates
4. The App Service managed identity has `AcrPull` role on the Container Registry
