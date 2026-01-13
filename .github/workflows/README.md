# GitHub Actions Deployment Configuration

This workflow builds the .NET application as a Docker container and deploys it to Azure App Service.

## Required Configuration

### GitHub Secrets

Create the following secret in your repository settings (**Settings** → **Secrets and variables** → **Actions** → **New repository secret**):

#### `AZURE_CREDENTIALS`
Service principal credentials for Azure authentication. Create using:

```bash
az ad sp create-for-rbac \
  --name "github-actions-zavastore" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group-name} \
  --sdk-auth
```

Copy the entire JSON output and paste it as the secret value.

### GitHub Variables

Create the following variables in your repository settings (**Settings** → **Secrets and variables** → **Actions** → **Variables** tab → **New repository variable**):

- **`ACR_NAME`**: Your Azure Container Registry name (e.g., `acrzvastoredevxyz123`)
- **`ACR_LOGIN_SERVER`**: Your ACR login server (e.g., `acrzvastoredevxyz123.azurecr.io`)
- **`AZURE_WEBAPP_NAME`**: Your App Service name (e.g., `app-zavastore-westus3-dev`)
- **`AZURE_RESOURCE_GROUP`**: Your resource group name (e.g., `rg-zavastore-westus3-dev`)

## Finding Your Resource Names

After deploying your infrastructure with Bicep, retrieve the resource names:

```bash
# List resource groups
az group list --query "[].name" -o table

# List resources in your resource group
az resource list --resource-group <your-rg-name> --query "[].{Name:name, Type:type}" -o table

# Get ACR login server
az acr list --resource-group <your-rg-name> --query "[0].loginServer" -o tsv
```

## Granting ACR Access

Ensure your App Service managed identity has permission to pull from ACR:

```bash
# Get App Service principal ID
APP_PRINCIPAL_ID=$(az webapp identity show \
  --name <your-app-name> \
  --resource-group <your-rg-name> \
  --query principalId -o tsv)

# Get ACR resource ID
ACR_ID=$(az acr show \
  --name <your-acr-name> \
  --resource-group <your-rg-name> \
  --query id -o tsv)

# Assign AcrPull role
az role assignment create \
  --assignee $APP_PRINCIPAL_ID \
  --role AcrPull \
  --scope $ACR_ID
```

## Triggering the Workflow

The workflow runs automatically on pushes to the `main` branch or can be triggered manually from the **Actions** tab.
