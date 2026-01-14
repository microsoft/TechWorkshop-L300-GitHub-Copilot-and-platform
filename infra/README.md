# ZavaStorefront Infrastructure

This folder contains the Bicep templates for deploying the ZavaStorefront application infrastructure to Azure using Azure Developer CLI (azd).

## Infrastructure Components

### Core Resources

- **Resource Group**: Container for all resources in Sweden Central region
- **Azure Container Registry (ACR)**: Stores Docker container images
- **App Service Plan**: Linux-based hosting plan (B1 SKU for dev)
- **App Service**: Web App for Containers to host the application
- **Log Analytics Workspace**: Centralized logging
- **Application Insights**: Application performance monitoring
- **Azure AI Hub**: Microsoft Foundry for GPT-4 and Phi model access

### Security

- **System-Assigned Managed Identity**: Enabled on the Web App
- **AcrPull Role Assignment**: Allows Web App to pull images from ACR without passwords
- **HTTPS Only**: Enforced on the Web App
- **No Admin Credentials**: ACR admin user disabled

## Folder Structure

```
infra/
├── main.bicep                      # Main orchestration template
├── main.parameters.json            # Parameter file
├── README.md                       # This file
└── modules/
    ├── log-analytics.bicep         # Log Analytics Workspace
    ├── app-insights.bicep          # Application Insights
    ├── container-registry.bicep    # Azure Container Registry
    ├── app-service-plan.bicep      # App Service Plan
    ├── web-app.bicep              # Web App for Containers
    ├── role-assignment.bicep       # RBAC role assignments
    └── ai-hub.bicep               # Azure AI Hub (Microsoft Foundry)
```

## Prerequisites

1. **Azure Subscription**: Active Azure subscription
2. **Azure CLI**: Installed and authenticated (`az login`)
3. **Azure Developer CLI (azd)**: Installed ([Installation Guide](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd))
4. **Permissions**: Contributor access to the subscription

## Deployment

### Using Azure Developer CLI (Recommended)

1. **Initialize the environment** (first time only):
   ```bash
   azd init
   ```

2. **Set the environment name**:
   ```bash
   azd env new <environment-name>
   ```
   Example: `azd env new dev`

3. **Set the location** (optional, defaults to swedencentral):
   ```bash
   azd env set AZURE_LOCATION swedencentral
   ```

4. **Provision infrastructure**:
   ```bash
   azd provision
   ```

5. **Build and deploy the application**:
   ```bash
   azd deploy
   ```

6. **Or do both in one command**:
   ```bash
   azd up
   ```

### Using Azure CLI with Bicep

If you prefer to use Azure CLI directly:

```bash
# Create resource group
az group create --name rg-zavastore-dev-swedencentral --location swedencentral

# Deploy infrastructure
az deployment group create \
  --resource-group rg-zavastore-dev-swedencentral \
  --template-file infra/main.bicep \
  --parameters environmentName=dev location=swedencentral
```

## Building and Deploying the Container

### Cloud-Based Build (No Local Docker Required)

Use Azure Container Registry to build the image in the cloud:

```bash
# Get the ACR name from outputs
ACR_NAME=$(azd env get-values | grep AZURE_CONTAINER_REGISTRY_NAME | cut -d'=' -f2)

# Build the container image in ACR
az acr build --registry $ACR_NAME --image zavastore:latest ./src
```

### Manual Container Deployment

After building the image, the Web App will automatically pull the latest image on restart:

```bash
# Restart the web app to pull the new image
az webapp restart --name <app-name> --resource-group <resource-group-name>
```

## Environment Variables

The following environment variables are automatically configured:

- `APPLICATIONINSIGHTS_CONNECTION_STRING`: Application Insights connection string
- `ApplicationInsightsAgent_EXTENSION_VERSION`: Version of Application Insights agent
- `APPINSIGHTS_INSTRUMENTATIONKEY`: Application Insights instrumentation key
- `DOCKER_REGISTRY_SERVER_URL`: ACR login server URL

## Outputs

After successful deployment, the following outputs are available:

```bash
azd env get-values
```

Key outputs:
- `AZURE_CONTAINER_REGISTRY_NAME`: Name of the Container Registry
- `AZURE_CONTAINER_REGISTRY_ENDPOINT`: ACR login server
- `AZURE_APP_SERVICE_NAME`: Name of the Web App
- `AZURE_APP_SERVICE_URL`: Public URL of the deployed application
- `APPLICATIONINSIGHTS_CONNECTION_STRING`: Application Insights connection string
- `AI_HUB_NAME`: Name of the AI Hub resource

## Monitoring

### Application Insights

Access Application Insights in the Azure Portal to view:
- Request rates and response times
- Failed requests and exceptions
- Application dependencies
- Custom metrics and events

### Log Analytics

Query logs using Kusto Query Language (KQL):

```bash
# Open Log Analytics in Azure Portal
az monitor log-analytics workspace show \
  --workspace-name law-zavastore-dev-swedencentral \
  --resource-group rg-zavastore-dev-swedencentral
```

### Container Logs

View container logs:

```bash
az webapp log tail --name <app-name> --resource-group <resource-group-name>
```

## Cost Optimization

Estimated monthly costs for dev environment:

- **Container Registry (Basic)**: ~$5/month
- **App Service Plan (B1)**: ~$13/month
- **Application Insights**: Pay-as-you-go (minimal for dev)
- **Log Analytics**: Pay-as-you-go (minimal for dev)
- **Storage**: <$1/month
- **AI Hub**: Token-based pricing

**Total**: ~$20-30/month for dev environment

## Cleanup

To delete all resources:

```bash
# Using azd
azd down --purge

# Or using Azure CLI
az group delete --name rg-zavastore-dev-swedencentral --yes --no-wait
```

## Troubleshooting

### Issue: Container fails to start

Check container logs:
```bash
az webapp log tail --name <app-name> --resource-group <resource-group-name>
```

### Issue: Cannot pull image from ACR

Verify role assignment:
```bash
az role assignment list --assignee <web-app-principal-id> --scope <acr-resource-id>
```

### Issue: AI Hub deployment fails

Check regional availability:
```bash
az provider show --namespace Microsoft.MachineLearningServices --query "resourceTypes[?resourceType=='workspaces'].locations"
```

## Additional Resources

- [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Azure App Service Documentation](https://learn.microsoft.com/azure/app-service/)
- [Azure Container Registry Documentation](https://learn.microsoft.com/azure/container-registry/)
- [Application Insights Documentation](https://learn.microsoft.com/azure/azure-monitor/app/app-insights-overview)
- [Azure AI Studio Documentation](https://learn.microsoft.com/azure/ai-studio/)
