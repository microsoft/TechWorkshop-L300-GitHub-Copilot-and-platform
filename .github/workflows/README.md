# GitHub Actions Deployment Setup

## Required GitHub Secrets

Configure the following secret in your GitHub repository settings (`Settings` → `Secrets and variables` → `Actions` → `New repository secret`):

### AZURE_CREDENTIALS

Azure service principal credentials in JSON format. Create using:

```bash
az ad sp create-for-rbac --name "github-actions-deploy" \
  --role contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP> \
  --sdk-auth
```

Copy the entire JSON output and paste it as the secret value.

## Required GitHub Variables

Configure the following variables in your GitHub repository settings (`Settings` → `Secrets and variables` → `Actions` → `Variables` tab → `New repository variable`):

| Variable Name | Description | Example Value |
|--------------|-------------|---------------|
| `ACR_NAME` | Azure Container Registry name | `acrzavastoredevabcd1234` |
| `APP_SERVICE_NAME` | Azure App Service name | `app-zavastore-dev-abcd1234` |
| `RESOURCE_GROUP` | Azure Resource Group name | `rg-zavastore-dev-eastus` |

## Finding Your Resource Names

After deploying your infrastructure with Bicep, retrieve the resource names:

```bash
# List resource groups
az group list --query "[].name" -o table

# List resources in your resource group
az resource list --resource-group <RESOURCE_GROUP> --query "[].{Name:name, Type:type}" -o table

# Get ACR name
az acr list --resource-group <RESOURCE_GROUP> --query "[0].name" -o tsv

# Get App Service name
az webapp list --resource-group <RESOURCE_GROUP> --query "[0].name" -o tsv
```

## Triggering the Workflow

The workflow automatically runs on:
- Push to `main` branch
- Manual trigger via GitHub Actions UI
