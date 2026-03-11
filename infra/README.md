# ZavaStorefront Infrastructure

This directory contains Azure infrastructure as code for deploying the ZavaStorefront web application to Azure using Bicep and Azure Developer CLI (AZD).

## Architecture Overview

The infrastructure consists of the following Azure resources deployed to a single resource group in **westus3**:

- **Azure Container Registry (ACR)**: Stores and manages Docker container images
- **App Service Plan**: Linux-based B1 SKU for development environment
- **Web App for Containers**: Runs the ZavaStorefront application as a Docker container
- **Application Insights**: Monitors application performance and health
- **Log Analytics Workspace**: Centralized logging and analytics backend
- **Managed Identity**: System-assigned identity for the Web App to securely pull images from ACR via RBAC

## File Structure

```
infra/
├── main.bicep                          # Root orchestration template
├── main.parameters.json                # Parameter values for deployment
├── modules/
│   ├── acr.bicep                      # Container Registry module
│   ├── appService.bicep               # App Service Plan and Web App module
│   ├── logAnalytics.bicep             # Log Analytics Workspace module
│   └── roleAssignment.bicep           # RBAC role assignment module
└── README.md                           # This file
```

## Key Features

### Security
- **Managed Identity**: Web App uses system-assigned managed identity (no password secrets)
- **RBAC**: AcrPull role assigned to Web App for ACR access
- **HTTPS Only**: Web App enforces HTTPS connections
- **TLS 1.2+**: Minimum TLS version requirement

### Monitoring & Diagnostics
- **Application Insights**: Real-time application performance monitoring
- **Log Analytics**: Centralized logging backend
- **Diagnostic Settings**: App Service diagnostics sent to Log Analytics
- **Retention**: 30-day retention for logs and metrics

### Deployment Configuration
- **Container Image**: Pulled from ACR on App Service startup
- **Environment**: Production environment configuration
- **Health Check**: Built-in Docker health check for container
- **Port**: Configured to listen on port 8080 (Azure App Service standard)

## Deployment Instructions

### Prerequisites

1. **Azure Subscription**: Ensure you have an active Azure subscription
2. **Azure CLI**: Install [Azure Developer CLI (azd)](https://aka.ms/azd/install)
3. **Docker**: Required for building container images (local) or use `az acr build` (cloud)
4. **.NET SDK**: For local development/testing (6.0 or later)

### Step 1: Initialize AZD Project

```bash
azd init
```

When prompted, select the current repository as the project root.

### Step 2: Authenticate with Azure

```bash
azd auth login
```

### Step 3: Set Subscription and Resource Group

```bash
azd config set defaults.subscription <subscription-id>
azd config set defaults.location westus3
```

### Step 4: Provision Infrastructure (Preview)

Validate the infrastructure without deploying:

```bash
azd provision --preview
```

Review the resources that will be created.

### Step 5: Deploy Infrastructure

```bash
azd up
```

This command will:
1. Provision the Azure resources defined in `main.bicep`
2. Build the container image (if Dockerfile exists)
3. Push the image to ACR
4. Deploy the image to the App Service

Alternatively, run provision and deploy separately:

```bash
azd provision
azd deploy
```

### Step 6: Build and Push Container Image (Without Local Docker)

If you don't have Docker installed locally, use Azure Container Registry's cloud build:

```bash
az acr build --registry <acr-name> -t zavastore:latest .
```

Then update the App Service with the new image:

```bash
az webapp config container set \
  --name <app-name> \
  --resource-group <rg-name> \
  --docker-custom-image-name <acr-name>.azurecr.io/zavastore:latest \
  --docker-registry-server-url https://<acr-name>.azurecr.io \
  --docker-registry-server-user <acr-username> \
  --docker-registry-server-password <acr-password>
```

**Note**: The Web App uses managed identity to pull from ACR, so you don't need to provide credentials.

### Step 7: Verify Deployment

Check the deployment status:

```bash
az deployment group show --name main \
  --resource-group rg-zavastore-dev-westus3 \
  --query "properties.provisioningState"
```

View the web app URL:

```bash
az webapp show --name app-zavastorefrontdev-dev \
  --resource-group rg-zavastore-dev-westus3 \
  --query "defaultHostName"
```

### Step 8: Monitor Application

Access Application Insights:

```bash
az monitor app-insights component show \
  --app app-zavastorefrontdev-dev-ai \
  --resource-group rg-zavastore-dev-westus3
```

## Bicep Module Parameters

### `main.bicep`

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `location` | string | `resourceGroup().location` | Azure region for resources |
| `environmentName` | string | Required | Environment name (e.g., 'dev', 'prod') |
| `resourceGroupName` | string | `resourceGroup().name` | Name of the resource group |
| `projectName` | string | 'zavastorefrontdev' | Project name for resource naming |
| `containerImage` | string | 'nginx:latest' | Docker image URI (ACR format) |

### `acr.bicep`

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `location` | string | Required | Azure region |
| `environmentName` | string | Required | Environment name |
| `acrName` | string | Required | ACR resource name |

### `appService.bicep`

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `location` | string | Required | Azure region |
| `environmentName` | string | Required | Environment name |
| `appServicePlanName` | string | Required | App Service Plan name |
| `webAppName` | string | Required | Web App name |
| `acrLoginServer` | string | Required | ACR login server FQDN |
| `acrName` | string | Required | ACR resource name |
| `logAnalyticsWorkspaceId` | string | Required | Log Analytics Workspace resource ID |
| `containerImage` | string | 'nginx:latest' | Docker image URI |

### `logAnalytics.bicep`

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `location` | string | Required | Azure region |
| `environmentName` | string | Required | Environment name |
| `logAnalyticsWorkspaceName` | string | Required | Log Analytics Workspace name |
| `retentionInDays` | int | 30 | Log retention period in days |

## Outputs

The `main.bicep` template provides the following outputs:

| Output | Type | Description |
|--------|------|-------------|
| `acrLoginServer` | string | ACR login server FQDN |
| `acrName` | string | ACR resource name |
| `acrId` | string | ACR resource ID |
| `webAppUrl` | string | Web App public URL (HTTPS) |
| `webAppName` | string | Web App resource name |
| `webAppId` | string | Web App resource ID |
| `appServicePlanId` | string | App Service Plan resource ID |
| `logAnalyticsWorkspaceId` | string | Log Analytics Workspace resource ID |
| `appInsightsInstrumentationKey` | string | Application Insights instrumentation key |

## Cost Optimization

The infrastructure is configured for a **development environment** with minimal cost:

- **App Service Plan**: B1 (Basic) tier - ~$12/month
- **Container Registry**: Basic tier - ~$5/month
- **Log Analytics**: Pay-per-gigabyte model (minimal for dev)
- **Application Insights**: No additional cost (uses Log Analytics)
- **Total Estimated Cost**: ~$17-25/month for dev environment

## Troubleshooting

### Container Image Pull Fails

1. Verify the image exists in ACR:
   ```bash
   az acr repository list --name <acr-name>
   ```

2. Check Web App logs:
   ```bash
   az webapp log tail --name <app-name> --resource-group <rg-name>
   ```

3. Verify managed identity has AcrPull role:
   ```bash
   az role assignment list --assignee <web-app-principal-id>
   ```

### Application Fails to Start

1. Check Application Insights traces
2. Review Web App diagnostic logs in Azure Portal
3. Verify environment variables are set correctly
4. Ensure the container is listening on port 8080

### Deployment Fails

1. Check resource quotas for westus3 region
2. Verify role permissions (Contributor or higher)
3. Review bicep template for syntax errors: `bicep build infra/main.bicep`
4. Check ACR region support for Microsoft Foundry (if needed)

## Cleanup

To remove all resources:

```bash
azd down
```

Or manually delete the resource group:

```bash
az group delete --name rg-zavastore-dev-westus3 --yes --no-wait
```

## References

- [Azure Container Registry](https://learn.microsoft.com/en-us/azure/container-registry/)
- [App Service for Containers](https://learn.microsoft.com/en-us/azure/app-service/quickstart-docker)
- [Application Insights](https://learn.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview)
- [Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/)
- [Microsoft Foundry](https://learn.microsoft.com/en-us/azure/ai-foundry/)
