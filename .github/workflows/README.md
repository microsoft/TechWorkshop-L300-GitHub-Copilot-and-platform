# GitHub Actions Deployment Setup

This workflow builds the ZavaStorefront .NET application as a Docker container and deploys it to Azure App Service.

## Required GitHub Secrets

Navigate to your repository **Settings** → **Secrets and variables** → **Actions**

### Secrets

Create the following secret:

- **`AZURE_CREDENTIALS`**: Azure service principal credentials in JSON format
  
  Generate using Azure CLI:
  ```bash
  az ad sp create-for-rbac \
    --name "github-actions-zavastore" \
    --role contributor \
    --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group-name} \
    --sdk-auth
  ```
  
  Copy the entire JSON output and paste it as the secret value.

## Required GitHub Variables

Navigate to your repository **Settings** → **Secrets and variables** → **Actions** → **Variables** tab

Create the following variables:

- **`ACR_NAME`**: Your Azure Container Registry name (e.g., `crzavastorexxxxx`)  crzavastorecumn44l5zcef2
- **`APP_SERVICE_NAME`**: Your Azure App Service name (e.g., `app-zavastore-dev-xxxxx`)  app-zavastore-dev-cumn44l5zcef2
- **`RESOURCE_GROUP`**: Your Azure Resource Group name (e.g., `rg-zavastore-dev-swedencentral`)

## Getting Azure Resource Names

After deploying your Bicep infrastructure, retrieve the values from Azure:

```bash
# Get ACR name
az acr list --resource-group {your-rg-name} --query "[0].name" -o tsv

#az acr list --resource-group rg-zavastore-dev-swedencentral --output table

# Get App Service name
az webapp list --resource-group {your-rg-name} --query "[0].name" -o tsv

# Get Resource Group name (if needed)
az group list --query "[?contains(name, 'zavastore')].name" -o tsv
```

## Triggering the Workflow

The workflow runs automatically on:
- Push to the `main` branch
- Manual trigger via GitHub Actions UI (workflow_dispatch)

## Workflow Steps

1. Checks out the code
2. Authenticates with Azure using service principal
3. Logs into Azure Container Registry
4. Builds Docker image from `./src/Dockerfile`
5. Tags and pushes image to ACR (with both commit SHA and `latest` tags)
6. Updates App Service to use the new container image
7. Restarts the App Service to apply changes
