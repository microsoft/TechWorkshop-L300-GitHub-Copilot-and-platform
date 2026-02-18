# GitHub Actions Deployment Setup

This workflow builds the .NET application as a Docker container and deploys it to Azure App Service.

## Required GitHub Secrets

Configure the following secrets in your GitHub repository (Settings → Secrets and variables → Actions):

### 1. AZURE_CREDENTIALS
Azure Service Principal credentials in JSON format. Create it using:

```bash
az ad sp create-for-rbac \
  --name "github-actions-zavastore" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group-name} \
  --sdk-auth
```

Copy the entire JSON output and add it as a secret.

### 2. ACR_NAME
The name of your Azure Container Registry (e.g., `acrzavastoreXXXXX`)

Find it with:
```bash
az acr list --resource-group {resource-group-name} --query "[0].name" -o tsv
```

### 3. RESOURCE_GROUP_NAME
The name of your Azure resource group (e.g., `rg-zavastore-dev-westus3`)

### 4. WEBAPP_NAME
The name of your Azure App Service (e.g., `app-zavastore-dev-XXXXX`)

Find it with:
```bash
az webapp list --resource-group {resource-group-name} --query "[0].name" -o tsv
```

## Additional Permissions

The service principal needs:
- **AcrPull** role on the Azure Container Registry
- **Contributor** role on the Resource Group

Grant ACR access:
```bash
az role assignment create \
  --assignee {service-principal-app-id} \
  --role AcrPush \
  --scope /subscriptions/{subscription-id}/resourceGroups/{resource-group-name}/providers/Microsoft.ContainerRegistry/registries/{acr-name}
```

## Workflow Triggers

- **Automatic**: Pushes to the `main` branch
- **Manual**: Via "Run workflow" button in GitHub Actions tab
