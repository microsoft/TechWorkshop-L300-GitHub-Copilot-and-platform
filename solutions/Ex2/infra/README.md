# ZavaStorefront Azure Infrastructure

This directory contains the Bicep templates and configuration for provisioning the Azure infrastructure for the ZavaStorefront application in the dev environment.

## Architecture Overview

The infrastructure deploys the following Azure resources in the **westus3** region:

- **Resource Group**: `rg-zavastore-dev-westus3`
- **Azure Container Registry (ACR)**: For storing Docker container images
- **App Service Plan**: Linux-based plan for hosting containers
- **Web App for Containers**: Linux-based App Service configured to pull from ACR
- **Application Insights**: For application monitoring and telemetry
- **Azure Foundry**: For GPT-5-mini and Phi-4 models

### Key Features

- **Managed Identity**: Web App uses system-assigned managed identity for secure ACR access
- **No Password Secrets**: ACR pull authentication via Azure RBAC (AcrPull role)
- **Cloud-based Builds**: Container images built using `az acr build` (no local Docker required)
- **Application Monitoring**: Integrated Application Insights for observability
- **AI Capabilities**: Azure Foundry with GPT-5-mini and Phi-4 deployments

## Prerequisites

1. **Azure CLI** (version 2.50.0 or later)
   ```bash
   az --version
   ```

2. **Azure Developer CLI (azd)** (recommended)
   ```bash
   azd version
   ```

3. **Azure Subscription** with appropriate permissions:
   - Contributor role on the subscription or resource group
   - Ability to create service principals and role assignments
   - Quota for Azure Foundry in westus3 region

4. **Bicep CLI** (included with Azure CLI)
   ```bash
   az bicep version
   ```

## Deployment Options

### Option 1: Using Azure Developer CLI (azd) - Recommended

The Azure Developer CLI provides a streamlined workflow for provisioning and deploying the application.

#### Initial Setup

1. **Install azd** (if not already installed):
   ```bash
   # Windows
   powershell -ex AllSigned -c "Invoke-RestMethod 'https://aka.ms/install-azd.ps1' | Invoke-Expression"
   
   # Linux/macOS
   curl -fsSL https://aka.ms/install-azd.sh | bash
   ```

2. **Initialize the environment**:
   ```bash
   azd auth login
   azd init
   ```

3. **Provision Azure resources**:
   ```bash
   azd provision
   ```
   
   This will:
   - Create all Azure resources using Bicep templates
   - Configure managed identity and role assignments
   - Set up Application Insights integration
   - Deploy Azure Foundry with model deployments

4. **Build and deploy the application**:
   ```bash
   azd deploy
   ```
   
   This will:
   - Build the Docker image using ACR build (cloud-based, no local Docker)
   - Push the image to ACR
   - Update the Web App to use the new image
   - Restart the Web App

#### Complete Workflow

```bash
# One-time setup
azd auth login
azd init

# Deploy infrastructure and application
azd up

# View deployed resources
azd show

# Monitor application
azd monitor

# Clean up resources
azd down
```

### Option 2: Using Azure CLI Directly

If you prefer to use Azure CLI without azd:

1. **Login to Azure**:
   ```bash
   az login
   az account set --subscription <your-subscription-id>
   ```

2. **Deploy the Bicep template**:
   ```bash
   az deployment sub create \
     --name zavastore-dev-deployment \
     --location westus3 \
     --template-file infra/main.bicep \
     --parameters infra/main.parameters.dev.json
   ```

3. **Capture outputs**:
   ```bash
   # Get the ACR name
   ACR_NAME=$(az deployment sub show \
     --name zavastore-dev-deployment \
     --query properties.outputs.acrName.value -o tsv)
   
   # Get the Web App name
   WEBAPP_NAME=$(az deployment sub show \
     --name zavastore-dev-deployment \
     --query properties.outputs.webAppName.value -o tsv)
   
   # Get the Resource Group name
   RG_NAME=$(az deployment sub show \
     --name zavastore-dev-deployment \
     --query properties.outputs.resourceGroupName.value -o tsv)
   ```

4. **Build and push the Docker image**:
   
   Using the deployment script (recommended):
   ```bash
   ./scripts/deploy.sh
   ```
   
   Or manually:
   ```bash
   az acr build \
     --registry $ACR_NAME \
     --image zavastore:latest \
     --file Dockerfile \
     ./src
   ```

5. **Update Web App to use the new image**:
   ```bash
   az webapp config container set \
     --name $WEBAPP_NAME \
     --resource-group $RG_NAME \
     --docker-custom-image-name $ACR_NAME.azurecr.io/zavastore:latest
   
   az webapp restart \
     --name $WEBAPP_NAME \
     --resource-group $RG_NAME
   ```

## Infrastructure Structure

```
infra/
├── main.bicep                      # Main orchestration template
├── main.parameters.dev.json        # Dev environment parameters
└── modules/
    ├── acr.bicep                   # Azure Container Registry
    ├── appServicePlan.bicep        # App Service Plan (Linux)
    ├── webApp.bicep                # Web App for Containers
    ├── appInsights.bicep           # Application Insights
    ├── openai.bicep                # Azure Foundry
    └── roleAssignment.bicep        # RBAC role assignments
```

## CI/CD with GitHub Actions

The repository includes a GitHub Actions workflow for automated container builds and deployments.

### Setup GitHub Actions

1. **Create a Service Principal**:
   ```bash
   az ad sp create-for-rbac \
     --name "github-actions-zavastore" \
     --role contributor \
     --scopes /subscriptions/<subscription-id> \
     --sdk-auth
   ```

2. **Configure GitHub Secrets**:
   - `AZURE_CLIENT_ID`: Client ID from service principal
   - `AZURE_TENANT_ID`: Tenant ID
   - `AZURE_SUBSCRIPTION_ID`: Subscription ID

3. **Configure GitHub Variables**:
   - `AZURE_CONTAINER_REGISTRY_NAME`: Name of your ACR (without .azurecr.io)
   - `AZURE_WEBAPP_NAME`: Name of your Web App
   - `AZURE_RESOURCE_GROUP`: Name of your Resource Group

4. **Trigger the workflow**:
   - Push changes to `main` or `develop` branch
   - Manually trigger via GitHub Actions UI

## Monitoring and Observability

### Application Insights

- **Portal**: Navigate to the Application Insights resource in the Azure Portal
- **Logs**: Use Log Analytics to query telemetry data
- **Metrics**: View real-time metrics and performance counters
- **Live Metrics**: Monitor live application performance

### Access Application Insights

```bash
# Get Application Insights connection string
az monitor app-insights component show \
  --app appi-zavastore-dev-westus3 \
  --resource-group rg-zavastore-dev-westus3 \
  --query connectionString -o tsv
```

## Azure Foundry Configuration

The infrastructure provisions Azure Foundry with the following deployments:

- **GPT-5-mini** (model: gpt-5-mini, version: 2025-08-07, capacity: 10)
- **Phi-4** (model: Phi-4, version: 7, capacity: 1)

### Access Azure Foundry

```bash
# Get Foundry endpoint
az cognitiveservices account show \
  --name oai-zavastore-dev-westus3 \
  --resource-group rg-zavastore-dev-westus3 \
  --query properties.endpoint -o tsv

# Get Foundry API key
az cognitiveservices account keys list \
  --name oai-zavastore-dev-westus3 \
  --resource-group rg-zavastore-dev-westus3 \
  --query key1 -o tsv
```

## Cost Optimization

The dev environment uses minimal-cost SKUs:

- **ACR**: Basic tier (~$5/month)
- **App Service Plan**: B1 tier (~$13/month)
- **Application Insights**: Pay-as-you-go (first 5GB free)
- **Azure Foundry**: S0 tier (pay-per-token)

### Cost Management Tips

1. **Stop the App Service** when not in use:
   ```bash
   az webapp stop --name $WEBAPP_NAME --resource-group $RG_NAME
   ```

2. **Delete the deployment** when done:
   ```bash
   azd down
   # or
   az group delete --name rg-zavastore-dev-westus3 --yes
   ```

3. **Monitor costs** in Azure Cost Management

## Troubleshooting

### ACR Pull Issues

If the Web App cannot pull images from ACR:

1. **Verify managed identity**:
   ```bash
   az webapp identity show \
     --name $WEBAPP_NAME \
     --resource-group $RG_NAME
   ```

2. **Verify role assignment**:
   ```bash
   az role assignment list \
     --assignee <principal-id> \
     --scope /subscriptions/<sub-id>/resourceGroups/$RG_NAME/providers/Microsoft.ContainerRegistry/registries/$ACR_NAME
   ```

3. **Check Web App logs**:
   ```bash
   az webapp log tail \
     --name $WEBAPP_NAME \
     --resource-group $RG_NAME
   ```

### Bicep Validation

Validate Bicep templates before deployment:

```bash
az bicep build --file infra/main.bicep
az deployment sub validate \
  --location westus3 \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.dev.json
```

### Azure Foundry Quota

If Azure Foundry deployment fails due to quota:

1. Check regional availability and quotas
2. Request quota increase in Azure Portal
3. Use alternative region (update `location` parameter)

## Additional Resources

- [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Web App for Containers](https://learn.microsoft.com/azure/app-service/quickstart-custom-container)
- [Azure Container Registry](https://learn.microsoft.com/azure/container-registry/)
- [Application Insights](https://learn.microsoft.com/azure/azure-monitor/app/app-insights-overview)
- [Azure Foundry Service](https://learn.microsoft.com/azure/ai-services/openai/)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Azure Activity Log for deployment errors
3. Open an issue in the repository
