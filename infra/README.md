# ZavaStore Infrastructure

This directory contains the Bicep infrastructure-as-code templates for deploying the ZavaStorefront application to Azure.

## Architecture

The infrastructure provisions the following Azure resources:

- **Azure Container Registry (ACR)** - Stores Docker container images with admin user enabled for development
- **Log Analytics Workspace** - Centralized logging and monitoring
- **Application Insights** - Application performance monitoring and diagnostics
- **App Service Plan** - Linux-based hosting plan (B1 SKU for development)
- **App Service** - Web app configured for Linux containers with system-assigned managed identity

## Resource Naming Convention

Resources are named using the following pattern:

- `acr{appname}{uniqueid}` - Azure Container Registry
- `log-{appname}-{env}-{uniqueid}` - Log Analytics Workspace
- `appi-{appname}-{env}-{uniqueid}` - Application Insights
- `asp-{appname}-{env}-{uniqueid}` - App Service Plan
- `app-{appname}-{env}-{uniqueid}` - App Service

Where:

- `{appname}` = Application name (default: `zavastore`)
- `{env}` = Environment (default: `dev`)
- `{uniqueid}` = Unique suffix generated from resource group ID

## Prerequisites

- Azure CLI installed and authenticated
- Azure Developer CLI (azd) installed
- An active Azure subscription
- Contributor access to create resources

## Deployment with Azure Developer CLI

### Initial Setup

```bash
# Initialize the environment
azd init

# Login to Azure
azd auth login

# Provision and deploy
azd up
```

### Preview Changes

```bash
# Preview what resources will be created
azd provision --preview
```

### Deploy Infrastructure Only

```bash
# Provision Azure resources without deploying the app
azd provision
```

### Deploy Application Only

```bash
# Deploy the application to existing infrastructure
azd deploy
```

## Manual Deployment with Azure CLI

```bash
# Create resource group
az group create --name rg-zavastore-dev --location eastus

# Deploy infrastructure
az deployment group create \
  --resource-group rg-zavastore-dev \
  --template-file infra/main.bicep \
  --parameters environmentName=dev applicationName=zavastore

# Build and push Docker image
az acr build \
  --registry <acr-name> \
  --image simplestore:latest \
  --file ./src/Dockerfile \
  ./src
```

## Parameters

The main Bicep template accepts the following parameters:

| Parameter         | Type   | Default                 | Description                     |
| ----------------- | ------ | ----------------------- | ------------------------------- |
| `environmentName` | string | `dev`                   | Environment name (max 10 chars) |
| `applicationName` | string | `zavastore`             | Application name (max 20 chars) |
| `location`        | string | Resource group location | Azure region for resources      |
| `dockerImageName` | string | `simplestore`           | Docker image name in ACR        |
| `dockerImageTag`  | string | `latest`                | Docker image tag                |

## Outputs

After deployment, the following outputs are available:

- `acrLoginServer` - ACR login server URL
- `acrName` - ACR name
- `appServiceUrl` - Application URL
- `appServiceName` - App Service name
- `appInsightsInstrumentationKey` - Application Insights instrumentation key
- `appInsightsConnectionString` - Application Insights connection string

## Security Features

- **Managed Identity**: App Service uses system-assigned managed identity to pull images from ACR
- **Role Assignment**: AcrPull role automatically assigned to App Service identity
- **HTTPS Only**: App Service enforces HTTPS
- **No Hardcoded Credentials**: No passwords or connection strings in code

## Monitoring

Application Insights is automatically configured with:

- Connection string injected into App Service settings
- Linked to Log Analytics workspace
- 30-day retention period

## Development Notes

- ACR admin user is enabled for development workflows
- App Service Plan uses B1 SKU (suitable for dev/test)
- Always On is disabled to reduce costs
- Port 80 is exposed for container communication

## Updating the Infrastructure

To make changes to the infrastructure:

1. Modify the Bicep files in `infra/modules/`
2. Test changes with `azd provision --preview`
3. Apply changes with `azd provision` or `azd up`

## Cleanup

To remove all provisioned resources:

```bash
# Delete all resources and resource group
azd down

# Or manually delete the resource group
az group delete --name rg-zavastore-dev --yes
```

## Module Structure

```
infra/
├── main.bicep                  # Root orchestration template
└── modules/
    ├── acr.bicep              # Azure Container Registry
    ├── logAnalytics.bicep     # Log Analytics Workspace
    ├── appInsights.bicep      # Application Insights
    ├── appServicePlan.bicep   # App Service Plan
    └── appService.bicep       # App Service with managed identity
```

## Cost Estimation

Estimated monthly costs (development environment):

- Azure Container Registry (Basic): ~$5
- App Service Plan (B1): ~$13
- Application Insights: Pay-as-you-go (minimal for dev)
- Log Analytics: Pay-as-you-go (minimal for dev)

**Total**: ~$20-25/month for development environment

## Troubleshooting

### Container fails to pull from ACR

- Verify managed identity is enabled on App Service
- Check AcrPull role assignment exists
- Ensure ACR admin user is enabled

### App Service shows "Application Error"

- Check Application Insights logs
- Verify WEBSITES_PORT matches container exposed port (80)
- Review container logs: `az webapp log tail --name <app-name> --resource-group <rg-name>`

### Deployment fails

- Ensure resource names are globally unique (handled automatically by uniqueString)
- Verify sufficient quota in target region
- Check Azure subscription permissions
