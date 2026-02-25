# Quick Start Deployment Guide

This guide provides step-by-step instructions for deploying the ZavaStorefront application to Azure.

## Prerequisites Checklist

Before starting, ensure you have:

- [ ] Active Azure subscription
- [ ] Azure CLI installed ([Download](https://docs.microsoft.com/cli/azure/install-azure-cli))
- [ ] Azure Developer CLI installed ([Download](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd))
- [ ] Git installed
- [ ] Contributor role on your Azure subscription

## Deployment Steps

### 1. Clone and Navigate to Repository

```bash
git clone <repository-url>
cd TechWorkshop-L300-GitHub-Copilot-and-platform
```

### 2. Authenticate with Azure

```bash
# Login to Azure
azd auth login

# This will open your browser for authentication
# Sign in with your Azure account
```

### 3. Initialize Environment

```bash
# Create a new environment (e.g., "dev", "staging", "prod")
azd env new zava-dev

# Set the Azure region to westus3
azd env set AZURE_LOCATION westus3
```

### 4. Provision Infrastructure

```bash
# Deploy all Azure resources
azd provision
```

This command will:
- Create resource group in westus3
- Deploy Azure Container Registry
- Deploy App Service Plan and Web App
- Deploy Application Insights and Log Analytics
- Deploy Azure OpenAI Service with GPT-4 and Phi models
- Configure RBAC permissions

**Expected Duration**: 3-5 minutes

### 5. Build and Push Container Image

After infrastructure provisioning completes, get the ACR name and build the container:

```bash
# Get the ACR name from environment
$acrName = azd env get-value AZURE_CONTAINER_REGISTRY_NAME

# Build and push container to ACR (cloud-based build - no local Docker needed)
az acr build `
  --registry $acrName `
  --image zava-storefront:latest `
  --file src/Dockerfile `
  src/
```

**Expected Duration**: 2-3 minutes

### 6. Verify Deployment

```bash
# Get the web app URL
$webAppUrl = azd env get-value AZURE_WEBAPP_URL

# Display the URL
Write-Host "Application URL: $webAppUrl"

# Open in browser
Start-Process $webAppUrl
```

The application should load showing the ZavaStorefront product catalog.

### 7. Monitor Application

View monitoring data in Azure Portal:

```bash
# Get Application Insights name
$appInsightsName = azd env get-value APPLICATIONINSIGHTS_NAME

# Open Application Insights in Azure Portal
az monitor app-insights component show `
  --app $appInsightsName `
  --resource-group (azd env get-value AZURE_RESOURCE_GROUP) `
  --output table
```

Or navigate to: Azure Portal → Application Insights → [Your App Insights resource] → Live Metrics

## Alternative: One-Command Deployment

For a streamlined deployment (provision + deploy):

```bash
azd up
```

This combines `azd provision` and the container build steps into one command.

## Post-Deployment Verification

### Check All Resources

```bash
# List all deployed resources
az resource list `
  --resource-group (azd env get-value AZURE_RESOURCE_GROUP) `
  --output table
```

You should see:
- Container Registry (ACR)
- App Service Plan
- App Service (Web App)
- Application Insights
- Log Analytics Workspace
- Azure OpenAI Account

### Test Health Endpoint

```bash
$webAppUrl = azd env get-value AZURE_WEBAPP_URL
Invoke-WebRequest -Uri "$webAppUrl/health"
```

Expected response: HTTP 200 OK with "Healthy" status

### View Application Logs

```bash
$webAppName = azd env get-value AZURE_WEBAPP_NAME
$resourceGroup = azd env get-value AZURE_RESOURCE_GROUP

# Stream logs
az webapp log tail `
  --name $webAppName `
  --resource-group $resourceGroup
```

## GitHub Actions Setup (Optional)

To enable automated deployments on git push:

### Option A: Using OIDC (Recommended)

1. **Create Service Principal**:

```bash
# Set variables
$appName = "zava-storefront-github"
$subscriptionId = (az account show --query id -o tsv)
$resourceGroup = azd env get-value AZURE_RESOURCE_GROUP

# Create app registration
$app = az ad app create --display-name $appName --query appId -o tsv

# Create service principal
az ad sp create --id $app

# Assign contributor role
az role assignment create `
  --assignee $app `
  --role Contributor `
  --scope "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup"

# Create federated credential
az ad app federated-credential create `
  --id $app `
  --parameters @- << EOF
{
  "name": "github-deploy",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:microsoft/TechWorkshop-L300-GitHub-Copilot-and-platform:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}
EOF
```

2. **GitHub Repository Variables** (Settings → Secrets and variables → Actions → Variables):

```
AZURE_CLIENT_ID: <app-id>
AZURE_TENANT_ID: <tenant-id>
AZURE_SUBSCRIPTION_ID: <subscription-id>
```

### Option B: Using Client Secret

```bash
# Create service principal with role assignment
az ad sp create-for-rbac `
  --name "zava-storefront-github" `
  --role Contributor `
  --scopes "/subscriptions/<subscription-id>" `
  --sdk-auth
```

Add the JSON output as a GitHub secret named `AZURE_CREDENTIALS`.

### Trigger Deployment

Push to main branch or manually trigger workflow:

```bash
git add .
git commit -m "Deploy infrastructure"
git push origin main
```

## Troubleshooting

### Issue: azd provision fails with permission error

**Solution**: Ensure you have Contributor role:

```bash
az role assignment create `
  --assignee <your-user-or-sp-id> `
  --role Contributor `
  --scope "/subscriptions/<subscription-id>"
```

### Issue: Container build fails

**Solution**: Check ACR permissions:

```bash
# Get your user principal ID
$principalId = az ad signed-in-user show --query id -o tsv

# Assign AcrPush role
az role assignment create `
  --assignee $principalId `
  --role AcrPush `
  --scope "/subscriptions/<subscription-id>/resourceGroups/<rg-name>/providers/Microsoft.ContainerRegistry/registries/<acr-name>"
```

### Issue: Web App shows "Container not found"

**Solution**: Verify image was pushed and restart Web App:

```bash
$acrName = azd env get-value AZURE_CONTAINER_REGISTRY_NAME
$webAppName = azd env get-value AZURE_WEBAPP_NAME
$resourceGroup = azd env get-value AZURE_RESOURCE_GROUP

# Check images in ACR
az acr repository list --name $acrName

# Restart Web App
az webapp restart --name $webAppName --resource-group $resourceGroup
```

### Issue: Application Insights shows no data

**Solution**: Verify connection string and generate traffic:

```bash
# Check app settings
az webapp config appsettings list `
  --name $webAppName `
  --resource-group $resourceGroup `
  | Select-String "APPLICATIONINSIGHTS"

# Generate traffic by browsing the site
# Data may take 2-5 minutes to appear
```

## Cleanup

To delete all Azure resources:

```bash
# Option 1: Using azd (recommended)
azd down --purge --force

# Option 2: Delete resource group manually
$resourceGroup = azd env get-value AZURE_RESOURCE_GROUP
az group delete --name $resourceGroup --yes --no-wait
```

## Cost Management

Monitor your spending:

```bash
# View cost analysis
az consumption usage list `
  --start-date "2026-02-01" `
  --end-date "2026-02-28" `
  --output table
```

**Estimated monthly cost for dev environment**: ~$33-78 USD (see [infra/README.md](../infra/README.md) for details)

## Next Steps

- Review [Infrastructure Documentation](../infra/README.md) for architecture details
- Set up [GitHub Actions](.github/workflows/azure-deploy.yml) for CI/CD
- Configure custom domain and SSL certificate
- Implement Azure Key Vault for secrets management
- Add Azure Front Door for global distribution
- Configure autoscaling rules

## Support

For issues:
1. Check [infra/README.md](../infra/README.md) troubleshooting section
2. Review Azure Portal diagnostics
3. Check Application Insights logs
4. File an issue in the repository

---

**Documentation Version**: 1.0  
**Last Updated**: February 2026
