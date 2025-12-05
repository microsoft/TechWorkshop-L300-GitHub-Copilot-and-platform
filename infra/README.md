# ZavaStorefront Azure Infrastructure

This directory contains the Azure infrastructure as code (IaC) using Bicep templates for deploying the ZavaStorefront web application.

## Architecture Overview

The infrastructure provisions the following Azure resources:

### Core Resources
- **Resource Group**: Logical container for all resources (`rg-zavastorefront-dev-westus3`)
- **Container Registry** (Basic SKU): Stores Docker container images with RBAC authentication
- **App Service Plan** (Linux, B1 SKU): Hosts the containerized web application
- **App Service**: Runs the .NET 6 web application in a Docker container
- **Log Analytics Workspace**: Centralized logging (30-day retention)
- **Application Insights**: Application performance monitoring and telemetry

### AI/ML Resources
- **Azure AI Foundry Hub**: AI workspace for model management
- **Azure AI Foundry Project**: Project-specific AI configuration
- **Key Vault**: Secure storage for AI secrets
- **Storage Account**: AI workspace storage

### Security & RBAC
- **Managed Identity**: System-assigned identity for App Service
- **AcrPull Role**: App Service → Container Registry (pull images)
- **Cognitive Services User Role**: App Service → AI Foundry (planned)

## Prerequisites

Before deploying, ensure you have:

1. **Azure CLI** (`az`) installed - [Install Guide](https://learn.microsoft.com/cli/azure/install-azure-cli)
2. **Azure Developer CLI** (`azd`) installed - [Install Guide](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd)
3. **Git** installed for versioning container images
4. **Azure Subscription** with sufficient permissions (Contributor or Owner)
5. **No Docker Desktop required** - Container builds happen in Azure Container Registry

### Verify Prerequisites

```powershell
# Check Azure CLI
az --version

# Check Azure Developer CLI
azd version

# Check Git
git --version

# Login to Azure
az login
azd auth login
```

## Deployment Steps

### Option 1: Using Azure Developer CLI (Recommended)

The Azure Developer CLI (`azd`) orchestrates the entire deployment workflow.

```powershell
# 1. Initialize the project (from repository root)
azd init

# 2. Provision Azure resources (creates infrastructure via Bicep)
azd provision

# 3. Deploy the application (builds container in ACR and deploys to App Service)
azd deploy
```

#### What happens during `azd provision`:
- Creates resource group in westus3
- Deploys all Bicep modules (monitoring, ACR, App Service Plan, App Service, AI Foundry)
- Configures RBAC role assignments
- Saves outputs to `.azure/<environment>/.env`

#### What happens during `azd deploy`:
- Runs `predeploy` hook: Builds Docker image in Azure Container Registry (no local Docker needed)
- Tags image with `latest` and Git commit hash
- Updates App Service configuration to use new image
- App Service automatically pulls image using Managed Identity

### Option 2: Manual Deployment with Azure CLI

If you prefer manual control:

```powershell
# 1. Create resource group
az group create --name rg-zavastorefront-dev-westus3 --location westus3

# 2. Deploy Bicep infrastructure
az deployment sub create `
  --location westus3 `
  --template-file infra/main.bicep `
  --parameters infra/main.parameters.json

# 3. Get Container Registry name from outputs
$acrName = az deployment sub show `
  --name main `
  --query properties.outputs.acrLoginServer.value `
  --output tsv | ForEach-Object { $_ -replace '\.azurecr\.io', '' }

# 4. Build and push Docker image to ACR (using ACR Tasks - no local Docker required)
az acr build `
  --registry $acrName `
  --image zava-storefront:latest `
  --file src/Dockerfile `
  src/

# 5. Get App Service name
$appName = az deployment sub show `
  --name main `
  --query properties.outputs.resourceIds.value.appService `
  --output tsv | Split-Path -Leaf

# 6. Restart App Service to pull new image
az webapp restart --name $appName --resource-group rg-zavastorefront-dev-westus3
```

## Accessing the Deployment

### Web Application

After deployment, access your application:

```powershell
# Get the App Service URL
azd env get-value APP_SERVICE_URL

# Or manually
az webapp show --name <app-name> --resource-group <resource-group> --query defaultHostName -o tsv
```

Navigate to `https://<hostname>` in your browser.

### Application Insights

Monitor application performance:

```powershell
# Get Application Insights name
$appInsightsName = az deployment sub show `
  --name main `
  --query properties.outputs.resourceIds.value.applicationInsights `
  --output tsv | Split-Path -Leaf

# Open in Azure Portal
az monitor app-insights component show `
  --app $appInsightsName `
  --resource-group <resource-group> `
  --query id -o tsv
```

### Container Registry

Verify container images:

```powershell
# List images in ACR
az acr repository list --name $acrName --output table

# Show tags for an image
az acr repository show-tags --name $acrName --repository zava-storefront --output table
```

## Configuration

### Environment Variables

The App Service is configured with the following environment variables:

- `APPLICATIONINSIGHTS_CONNECTION_STRING`: Application Insights telemetry
- `ApplicationInsightsAgent_EXTENSION_VERSION`: App Insights agent version (~3)
- `APPINSIGHTS_INSTRUMENTATIONKEY`: App Insights key
- `DOCKER_REGISTRY_SERVER_URL`: ACR login server URL
- `WEBSITES_PORT`: Container port (80)
- `DOCKER_ENABLE_CI`: Enable continuous deployment from ACR

### Updating Application Settings

```powershell
az webapp config appsettings set `
  --name <app-name> `
  --resource-group <resource-group> `
  --settings KEY=VALUE
```

## Infrastructure Updates

### Modifying Bicep Templates

1. Edit files in `infra/modules/` or `infra/main.bicep`
2. Validate Bicep syntax:
   ```powershell
   az bicep build --file infra/main.bicep
   ```
3. Deploy changes:
   ```powershell
   azd provision
   ```

### Scaling Resources

To change App Service Plan SKU:

```powershell
# Edit infra/main.parameters.json or use inline parameters
az deployment sub create `
  --location westus3 `
  --template-file infra/main.bicep `
  --parameters environmentName=dev location=westus3 projectName=ZavaStorefront appServiceSkuName=S1
```

## Continuous Integration / Continuous Deployment (CI/CD)

### GitHub Actions Integration

Create `.github/workflows/azure-deploy.yml`:

```yaml
name: Deploy to Azure

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Install azd
        uses: Azure/setup-azd@v0.1.0
      
      - name: Deploy with azd
        run: |
          azd provision --no-prompt
          azd deploy --no-prompt
        env:
          AZURE_ENV_NAME: dev
          AZURE_LOCATION: westus3
          AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

## Troubleshooting

### Container Image Not Pulling

**Symptom**: App Service shows "Container didn't respond to HTTP pings"

**Solution**:
1. Verify Managed Identity has AcrPull role:
   ```powershell
   az role assignment list --assignee <app-service-principal-id> --all
   ```
2. Check App Service logs:
   ```powershell
   az webapp log tail --name <app-name> --resource-group <resource-group>
   ```

### ACR Build Fails

**Symptom**: `az acr build` command fails

**Solution**:
1. Verify Azure CLI is logged in:
   ```powershell
   az account show
   ```
2. Check ACR permissions:
   ```powershell
   az acr show --name <acr-name> --query loginServer
   ```
3. Validate Dockerfile syntax in `src/Dockerfile`

### Application Insights Not Receiving Telemetry

**Symptom**: No data in Application Insights

**Solution**:
1. Verify connection string is set:
   ```powershell
   az webapp config appsettings list --name <app-name> --resource-group <resource-group> | Select-String "APPLICATIONINSIGHTS"
   ```
2. Check Application Insights instrumentation key:
   ```powershell
   az monitor app-insights component show --app <app-insights-name> --resource-group <resource-group>
   ```
3. Restart App Service:
   ```powershell
   az webapp restart --name <app-name> --resource-group <resource-group>
   ```

### AI Foundry Hub Provisioning Issues

**Symptom**: AI Hub deployment fails

**Solution**:
1. Verify region supports AI Foundry (westus3 confirmed)
2. Check resource provider registration:
   ```powershell
   az provider show --namespace Microsoft.MachineLearningServices
   az provider register --namespace Microsoft.MachineLearningServices
   ```

## Cost Estimation

Estimated monthly costs (westus3, dev environment):

| Resource | SKU/Tier | Estimated Cost |
|----------|----------|----------------|
| App Service Plan | B1 (1 instance) | ~$13.14/month |
| Container Registry | Basic | ~$5.00/month |
| Log Analytics Workspace | Pay-as-you-go (30-day retention) | ~$2-5/month (depending on ingestion) |
| Application Insights | Pay-as-you-go | ~$2-5/month (depending on telemetry) |
| AI Foundry Hub | Basic | ~$0 (without model deployments) |
| Storage Account | Standard LRS | ~$1/month |
| Key Vault | Standard | ~$0.03/month (vault only) |
| **Total** | | **~$23-29/month** |

**Note**: Costs exclude data transfer, model deployments, and AI service consumption.

## Cleanup

To delete all resources:

```powershell
# Using Azure Developer CLI
azd down --purge

# Or manually
az group delete --name rg-zavastorefront-dev-westus3 --yes --no-wait
```

## Security Best Practices

✅ **Implemented**:
- HTTPS-only enforcement on App Service
- Managed Identity for service-to-service authentication (no credentials in code)
- RBAC-based ACR access (admin user disabled)
- TLS 1.2 minimum encryption
- Non-root container user in Dockerfile
- Secrets stored in App Settings (encrypted at rest)
- Application Insights connection string marked as `@secure()`

🔒 **Recommended for Production**:
- Enable Azure DDoS Protection on virtual network
- Configure Azure Front Door for WAF and CDN
- Upgrade ACR to Premium for private endpoints and geo-replication
- Enable Azure Key Vault for application secrets
- Configure network isolation with VNet integration
- Enable Azure Defender for App Service
- Implement Azure Policy for compliance enforcement

## Additional Resources

- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [App Service Linux Containers](https://learn.microsoft.com/azure/app-service/configure-custom-container)
- [Azure Container Registry](https://learn.microsoft.com/azure/container-registry/)
- [Application Insights for .NET](https://learn.microsoft.com/azure/azure-monitor/app/asp-net-core)
- [Azure AI Foundry](https://learn.microsoft.com/azure/ai-studio/)

## Support

For issues or questions:
1. Check [Troubleshooting](#troubleshooting) section
2. Review Azure Portal diagnostics and logs
3. Open a GitHub issue with deployment logs
4. Contact Azure Support for subscription-level issues
