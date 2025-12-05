# GitHub Actions Deployment Configuration

This workflow automatically builds and deploys the ZavaStorefront .NET application as a container to Azure App Service.

## Required GitHub Secrets

Configure the following secrets in your repository settings (`Settings` → `Secrets and variables` → `Actions` → `New repository secret`):

### 1. `AZURE_CREDENTIALS`
Azure service principal credentials for deployment.

**To create:**
```bash
az ad sp create-for-rbac --name "github-actions-zava" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group-name} \
  --sdk-auth
```

Copy the entire JSON output and paste it as the secret value.

### 2. `ACR_USERNAME`
Azure Container Registry username.

**To get:**
```bash
az acr credential show --name {acr-name} --query username -o tsv
```

### 3. `ACR_PASSWORD`
Azure Container Registry password.

**To get:**
```bash
az acr credential show --name {acr-name} --query passwords[0].value -o tsv
```

**Note:** Your Container Registry must have admin user enabled. To enable:
```bash
az acr update --name {acr-name} --admin-enabled true
```

## Required GitHub Variables

Configure the following variables in your repository settings (`Settings` → `Secrets and variables` → `Actions` → `Variables` tab → `New repository variable`):

### 1. `AZURE_WEBAPP_NAME`
The name of your Azure App Service.

**Example:** `azapp<unique-token>`

**To get:**
```bash
az webapp list --resource-group {resource-group-name} --query "[0].name" -o tsv
```

### 2. `AZURE_CONTAINER_REGISTRY`
The login server URL of your Azure Container Registry.

**Example:** `azacr<unique-token>.azurecr.io`

**To get:**
```bash
az acr show --name {acr-name} --query loginServer -o tsv
```

## Deployment

The workflow triggers automatically on:
- Push to the `main` branch
- Manual trigger via the Actions tab

The workflow will:
1. Build the Docker image from `src/Dockerfile`
2. Push the image to Azure Container Registry
3. Deploy the container to Azure App Service

## First-Time Setup Checklist

- [ ] Deploy infrastructure using `infra/main.bicep`
- [ ] Enable ACR admin user (if using password authentication)
- [ ] Create Azure service principal with contributor role
- [ ] Add all required secrets to GitHub repository
- [ ] Add all required variables to GitHub repository
- [ ] Push code to `main` branch or manually trigger workflow
