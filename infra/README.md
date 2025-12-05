# Azure Infrastructure for ZavaStorefront

This directory contains the Bicep templates for deploying the ZavaStorefront application infrastructure to Azure.

## Architecture Overview

The infrastructure includes the following Azure resources:

- **Resource Group**: Container for all resources (`rg-zavastore-dev-westus3`)
- **Azure Container Registry (ACR)**: Stores Docker images for the application
- **App Service Plan**: Linux-based plan for hosting containerized apps
- **App Service (Web App)**: Hosts the .NET 6 ZavaStorefront application as a container
- **Application Insights**: Monitors application performance and availability
- **Azure AI Foundry (Cognitive Services)**: Provides GPT-4 and Phi AI models
- **Role Assignments**: System-assigned managed identity with AcrPull permissions

## Prerequisites

Before deploying, ensure you have:

1. **Azure CLI** installed and authenticated
   ```bash
   az login
   az account set --subscription "<your-subscription-id>"
   ```

2. **Azure Developer CLI (azd)** installed
   ```bash
   # Windows (PowerShell)
   powershell -ex AllSigned -c "Invoke-RestMethod 'https://aka.ms/install-azd.ps1' | Invoke-Expression"
   
   # macOS/Linux
   curl -fsSL https://aka.ms/install-azd.sh | bash
   ```

3. **Permissions**: Contributor role on the target subscription

## Project Structure

```
infra/
├── main.bicep                    # Main orchestration template
├── main.parameters.json          # Environment parameters
└── modules/
    ├── acr.bicep                # Azure Container Registry
    ├── appServicePlan.bicep     # App Service Plan
    ├── webApp.bicep             # Web App for Containers
    ├── appInsights.bicep        # Application Insights
    ├── foundry.bicep            # Azure AI Foundry
    └── roleAssignment.bicep     # RBAC role assignments
```

## Deployment Steps

### Option 1: Using Azure Developer CLI (Recommended)

1. **Initialize azd environment**:
   ```bash
   azd init
   ```

2. **Provision infrastructure**:
   ```bash
   azd provision
   ```
   This will:
   - Create all Azure resources
   - Configure managed identity and permissions
   - Output resource names and endpoints

3. **Build and push Docker image to ACR** (cloud-based, no local Docker needed):
   ```bash
   az acr build --registry <acr-name> --image zava-storefront:latest ./src
   ```

4. **Deploy application**:
   ```bash
   azd deploy
   ```

### Option 2: Using Azure CLI Directly

1. **Deploy infrastructure**:
   ```bash
   az deployment sub create \
     --location westus3 \
     --template-file infra/main.bicep \
     --parameters infra/main.parameters.json
   ```

2. **Get outputs**:
   ```bash
   az deployment sub show \
     --name main \
     --query properties.outputs
   ```

3. **Build and push Docker image**:
   ```bash
   ACR_NAME=$(az deployment sub show --name main --query properties.outputs.acrName.value -o tsv)
   az acr build --registry $ACR_NAME --image zava-storefront:latest ./src
   ```

4. **Restart the web app** to pull the new image:
   ```bash
   WEBAPP_NAME=$(az deployment sub show --name main --query properties.outputs.webAppName.value -o tsv)
   RG_NAME=$(az deployment sub show --name main --query properties.outputs.resourceGroupName.value -o tsv)
   az webapp restart --name $WEBAPP_NAME --resource-group $RG_NAME
   ```

## Configuration

### Parameters

Edit `main.parameters.json` to customize:

- `environmentName`: Environment identifier (dev, test, prod)
- `location`: Azure region (default: westus3)
- `appName`: Application name prefix (default: zavastore)

### Resource Naming Convention

Resources follow Azure naming best practices:

- Resource Group: `rg-{appName}-{env}-{location}`
- ACR: `acr{appName}{env}{unique}`
- App Service Plan: `asp-{appName}-{env}`
- Web App: `app-{appName}-{env}-{unique}`
- Application Insights: `appi-{appName}-{env}`
- AI Foundry: `cog-{appName}-{env}-{unique}`

## Security Features

✅ **No Admin Credentials**: ACR admin user is disabled  
✅ **Managed Identity**: Web App uses system-assigned identity for ACR access  
✅ **RBAC**: AcrPull role assigned automatically  
✅ **HTTPS Only**: TLS 1.2+ enforced on Web App  
✅ **No Secrets**: No passwords stored in configuration  

## Monitoring

Application Insights is automatically configured with:

- Connection string injected as environment variable
- Application Insights agent enabled
- Real-time telemetry collection

Access monitoring:
```bash
az monitor app-insights component show \
  --app <appInsightsName> \
  --resource-group <rgName>
```

## Cost Estimation (Development Environment)

| Resource | SKU | Estimated Monthly Cost |
|----------|-----|------------------------|
| ACR | Basic | ~$5 |
| App Service Plan | B1 | ~$13 |
| Application Insights | Pay-as-you-go | ~$2-5 |
| Azure AI Foundry | S0 + usage | ~$10-30 |
| **Total** | | **~$30-53/month** |

## Cleanup

To delete all resources:

```bash
# Using azd
azd down --purge

# Or using Azure CLI
az group delete --name rg-zavastore-dev-westus3 --yes
```

## Troubleshooting

### Web App not starting

Check logs:
```bash
az webapp log tail --name <webAppName> --resource-group <rgName>
```

### ACR authentication issues

Verify role assignment:
```bash
az role assignment list --assignee <principalId> --scope <acrId>
```

### Deployment errors

View deployment operations:
```bash
az deployment sub show --name main
az deployment operation sub list --name main
```

## Additional Resources

- [Azure App Service Documentation](https://docs.microsoft.com/azure/app-service/)
- [Azure Container Registry Documentation](https://docs.microsoft.com/azure/container-registry/)
- [Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
