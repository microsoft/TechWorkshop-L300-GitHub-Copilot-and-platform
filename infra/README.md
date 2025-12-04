# ZavaStorefront Azure Infrastructure

This directory contains the Infrastructure as Code (IaC) for deploying the ZavaStorefront web application to Azure.

## Architecture Overview

The infrastructure provisions a **dev environment** in **westus3** with the following Azure resources:

- **Resource Group**: Single resource group containing all resources
- **User-Assigned Managed Identity**: Enables RBAC between services (no passwords)
- **Azure Container Registry (ACR)**: Stores Docker container images
- **App Service Plan (Linux)**: B1 SKU for hosting containerized applications
- **App Service**: Runs the .NET 6 ASP.NET MVC web application in a Docker container
- **Log Analytics Workspace**: Centralized logging and monitoring
- **Application Insights**: Performance monitoring and telemetry

## Key Design Decisions

### 🔐 RBAC-Based Authentication
- **No passwords or access keys** are used
- App Service uses a User-Assigned Managed Identity
- Managed Identity has `AcrPull` role on the Container Registry
- Secure, Azure-native authentication pattern

### 🐧 Linux App Service with Containers
- App Service runs on **Linux** (required for Docker containers)
- Application is containerized using multi-stage Dockerfile
- Port 8080 is used (Azure App Service default for containers)
- No local Docker installation required on developer machines

### 📊 Monitoring & Diagnostics
- Application Insights integrated via connection string
- Diagnostic settings enabled on App Service
- Logs sent to Log Analytics Workspace
- Includes HTTP logs, console logs, and application logs

### 🏷️ Resource Naming Convention
All resources follow the pattern: `az{prefix}{uniqueToken}`

- `az` prefix identifies Azure resources
- `{prefix}` is a 2-3 character resource type identifier (e.g., `acr`, `app`, `mi`)
- `{uniqueToken}` is generated from subscription, resource group, location, and environment name
- Ensures globally unique names and consistency

**Examples:**
- Container Registry: `azacrxyz123abc`
- App Service: `azappxyz123abc`
- Managed Identity: `azmixyz123abc`
- Application Insights: `azaixyz123abc`

### 🏗️ Deployment Strategy
- **Azure Developer CLI (AZD)** for streamlined deployment
- **Bicep** for Infrastructure as Code
- Single command deployment: `azd up`
- Automatic resource provisioning and application deployment

## File Structure

```
infra/
├── main.bicep              # Main infrastructure template
├── main.parameters.json    # Environment parameters
└── README.md               # This file
```

## Prerequisites

- [Azure Developer CLI (azd)](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd)
- [Azure CLI (az)](https://learn.microsoft.com/cli/azure/install-azure-cli)
- Azure subscription with appropriate permissions

## Deployment Instructions

### 1. Initialize AZD Environment

```powershell
# Navigate to repository root
cd c:\repos\learn\mcaps-trainings\TechWorkshop-L300-GitHub-Copilot-and-platform

# Initialize azd (first time only)
azd init

# Set environment variables
azd env set AZURE_LOCATION westus3
```

### 2. Preview Deployment

```powershell
# Preview what will be deployed (recommended)
azd provision --preview
```

### 3. Deploy Infrastructure and Application

```powershell
# Deploy everything (infrastructure + application)
azd up
```

This command will:
1. Create the resource group
2. Deploy all Bicep resources
3. Build the Docker container
4. Push the image to Azure Container Registry
5. Deploy the container to App Service
6. Configure all RBAC permissions

### 4. Verify Deployment

After deployment, `azd` will output:
- App Service URL: `https://azappXXXXXX.azurewebsites.net`
- Container Registry endpoint
- Application Insights connection string

Visit the App Service URL to verify the application is running.

## Bicep Template Details

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `environmentName` | string | - | Name of the environment (from `$AZURE_ENV_NAME`) |
| `location` | string | Resource Group location | Azure region for resources |
| `appServiceName` | string | `azapp{token}` | Optional override for App Service name |
| `containerRegistryName` | string | `azacr{token}` | Optional override for ACR name |
| `appServicePlanSku` | string | `B1` | App Service Plan SKU |

### Key Outputs

| Output | Description |
|--------|-------------|
| `SERVICE_WEB_URI` | Public URL of the deployed web application |
| `AZURE_CONTAINER_REGISTRY_ENDPOINT` | ACR login server URL |
| `RESOURCE_GROUP_ID` | Azure resource ID of the resource group |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | Application Insights connection string |

### RBAC Configuration

The template automatically configures:

```bicep
// Grant App Service managed identity AcrPull role on Container Registry
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistry.id, managedIdentity.id, acrPullRoleDefinitionId)
  scope: containerRegistry
  properties: {
    roleDefinitionId: acrPullRoleDefinitionId  // AcrPull built-in role
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}
```

## Troubleshooting

### Deployment Failures

```powershell
# View deployment logs
azd deploy --debug

# Check resource group in Azure Portal
az group show --name rg-{environmentName}
```

### Container Not Starting

```powershell
# View App Service logs
az webapp log tail --name {appServiceName} --resource-group rg-{environmentName}

# Check diagnostic settings in Azure Portal
```

### RBAC Permission Issues

```powershell
# Verify role assignment
az role assignment list --scope /subscriptions/{subscriptionId}/resourceGroups/{rgName}/providers/Microsoft.ContainerRegistry/registries/{acrName}
```

## Future Enhancements (Not in Scope for Issue #2)

- Microsoft Foundry AI Hub integration (GPT-4, Phi models)
- Custom domain and SSL certificates
- Auto-scaling configuration
- Production environment setup
- CI/CD pipeline integration

## Tags

All resources include the following tags:
- `azd-env-name`: Environment name for AZD tracking
- `environment`: `dev`
- `project`: `zava-storefront`

Additionally, the App Service includes:
- `azd-service-name`: `web` (required by AZD for service mapping)

## Security Best Practices Applied

✅ HTTPS only enabled on App Service  
✅ Admin user disabled on Container Registry  
✅ Anonymous pull access disabled on ACR  
✅ FTPS disabled on App Service  
✅ Managed Identity used for service-to-service authentication  
✅ No hardcoded credentials or secrets  
✅ Diagnostic logging enabled for audit trails  

## Resource Costs (Approximate)

For dev environment with B1 App Service Plan:
- **App Service Plan (B1)**: ~$13/month
- **Container Registry (Basic)**: ~$5/month
- **Application Insights**: Pay-as-you-go (minimal for dev)
- **Log Analytics**: Pay-as-you-go (minimal for dev)

**Total**: ~$20-25/month

## Related Documentation

- [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [App Service with Containers](https://learn.microsoft.com/azure/app-service/quickstart-custom-container)
- [Azure Container Registry](https://learn.microsoft.com/azure/container-registry/)
- [Managed Identities](https://learn.microsoft.com/azure/active-directory/managed-identities-azure-resources/)
