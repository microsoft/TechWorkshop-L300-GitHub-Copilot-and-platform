# ZavaStorefront Azure Infrastructure - Bicep Templates

This directory contains Bicep templates for deploying the ZavaStorefront web application infrastructure on Azure using Azure Developer CLI (AZD).

## Directory Structure

```
infra/
├── main.bicep                      # Root template - orchestrates all modules
├── main.parameters.json            # Parameter values for deployments
├── README.md                        # This file
└── modules/
    ├── acr.bicep                   # Azure Container Registry module
    ├── appInsights.bicep           # Application Insights module
    ├── appService.bicep            # App Service Plan & Web App module
    ├── keyVault.bicep              # Key Vault module
    ├── logAnalytics.bicep          # Log Analytics Workspace module
    └── managedIdentity.bicep       # Managed Identity module
```

## Overview

The Bicep templates define a complete infrastructure stack for ZavaStorefront:

- **Azure Container Registry (ACR)**: Stores Docker container images
- **App Service Plan & Web App**: Hosts the ASP.NET Core application in a Docker container
- **Application Insights**: Monitors application performance and health
- **Log Analytics Workspace**: Centralized logging and analytics
- **Managed Identity**: Provides RBAC-based authentication (no passwords)
- **Key Vault**: Securely stores secrets and configuration (optional)

## Key Features

### Security
- **RBAC-Based Access**: Uses Managed Identity with role assignments instead of passwords
- **No Admin Passwords**: Container Registry admin access disabled
- **HTTPS Only**: App Service enforces HTTPS connections
- **Secure Secrets**: Key Vault integration for credential management

### Observability
- **Application Insights**: Real-time monitoring of application performance
- **Log Analytics**: Centralized logging for troubleshooting and analysis
- **Alert Rules**: Automatic alerts for high CPU and memory usage
- **Health Checks**: App Service health check configuration

### Scalability
- **Configurable SKUs**: App Service Plan SKU can be adjusted per environment
- **Instance Count**: Easily scale number of instances
- **Auto-Scaling Ready**: Infrastructure supports adding auto-scale rules

## Parameters

### Required Parameters
- `environmentName`: Environment name (e.g., "dev", "staging", "prod")
- `location`: Azure region (e.g., "westus3")
- `resourcePrefix`: Naming prefix for all resources (e.g., "zava-storefront")

### Container Parameters
- `containerImageName`: Docker image name in ACR (e.g., "zavastorefront")
- `containerImageTag`: Docker image tag/version (e.g., "latest", "v1.0.0")

### Compute Parameters
- `appServicePlanSku`: App Service Plan SKU (B1, B2, B3, S1, P1V2, etc.)
- `appServiceInstanceCount`: Number of instances (default: 1)

### Feature Flags
- `enableAppInsights`: Enable Application Insights (default: true)
- `enableKeyVault`: Enable Key Vault (default: true)

## Deployment

### Prerequisites
1. Azure CLI (`az`) installed
2. Azure Developer CLI (`azd`) installed
3. Docker installed (for building container images)
4. Appropriate Azure permissions (Contributor or higher)

### Using AZD (Recommended)

```bash
# Initialize AZD project (one-time setup)
azd init --template ./infra

# Provision Azure resources
azd provision

# Deploy application
azd deploy
```

### Using Azure CLI

```bash
# Create resource group
az group create --name rg-zava-storefront-dev --location westus3

# Deploy Bicep template
az deployment group create \
  --resource-group rg-zava-storefront-dev \
  --template-file main.bicep \
  --parameters main.parameters.json
```

### Using PowerShell

```powershell
# Deploy Bicep template
New-AzResourceGroupDeployment `
  -ResourceGroupName rg-zava-storefront-dev `
  -TemplateFile main.bicep `
  -TemplateParameterFile main.parameters.json
```

## Outputs

After successful deployment, the Bicep templates output:

- `resourceGroupName`: Name of the created resource group
- `acrUrl`: Azure Container Registry login server URL
- `appServiceUrl`: Web app public URL
- `appInsightsInstrumentationKey`: Application Insights instrumentation key
- `logAnalyticsWorkspaceId`: Log Analytics workspace ID
- `managedIdentityClientId`: Managed Identity client ID for authentication
- `keyVaultUri`: Key Vault URI (if enabled)
- `deploymentSummary`: Summary of all deployed resources

## Container Deployment

### Building the Docker Image

```bash
# Build Docker image
docker build -f Dockerfile -t zavastorefront:latest .

# Tag for ACR
docker tag zavastorefront:latest <acr-name>.azurecr.io/zavastorefront:latest
```

### Pushing to ACR

```bash
# Authenticate with ACR
az acr login --name <acr-name>

# Push image
docker push <acr-name>.azurecr.io/zavastorefront:latest
```

### Updating App Service

```bash
# Update App Service to use new image
az webapp config container set \
  --name app-zava-storefront-dev \
  --resource-group rg-zava-storefront-dev \
  --docker-custom-image-name <acr-name>.azurecr.io/zavastorefront:latest \
  --docker-registry-server-url https://<acr-name>.azurecr.io \
  --docker-registry-server-user <managed-identity-client-id>
```

## Monitoring

### Application Insights Queries

View recent requests:
```kusto
requests
| where timestamp > ago(24h)
| summarize count() by url, resultCode
| order by count_ desc
```

View exceptions:
```kusto
exceptions
| where timestamp > ago(24h)
| summarize count() by type, problemId
| order by count_ desc
```

View performance:
```kusto
requests
| where timestamp > ago(1h)
| summarize avg(duration), percentile(duration, 95) by url
```

### Accessing Logs

```bash
# Stream App Service logs
az webapp log tail -g rg-zava-storefront-dev -n app-zava-storefront-dev

# Download logs
az webapp log download -g rg-zava-storefront-dev -n app-zava-storefront-dev
```

## Scaling

### Vertical Scaling (Change SKU)

```bash
az appservice plan update \
  --name asp-zava-storefront-dev \
  --resource-group rg-zava-storefront-dev \
  --sku B3
```

### Horizontal Scaling (More Instances)

Update `appServiceInstanceCount` parameter and redeploy:

```bash
az deployment group create \
  --resource-group rg-zava-storefront-dev \
  --template-file main.bicep \
  --parameters main.parameters.json appServiceInstanceCount=3
```

## Cleanup

### Delete All Resources

```bash
# Delete resource group (removes all resources)
az group delete --name rg-zava-storefront-dev --yes
```

### Using AZD

```bash
azd down
```

## Troubleshooting

### Container won't start
- Check App Service logs: `az webapp log tail -g rg-zava-storefront-dev -n app-zava-storefront-dev`
- Verify image is in ACR: `az acr repository list --name <acr-name>`
- Check image tag: `az acr repository show-tags --name <acr-name> --repository zavastorefront`

### ACR authentication issues
- Verify Managed Identity has AcrPull role: `az role assignment list --scope /subscriptions/<subscription-id>/resourceGroups/rg-zava-storefront-dev/providers/Microsoft.ContainerRegistry/registries/<acr-name>`
- Check App Service identity: `az webapp identity show -g rg-zava-storefront-dev -n app-zava-storefront-dev`

### Application Insights not collecting data
- Verify instrumentation key in App Service settings
- Check Application Insights connection string
- Review Application Insights sampling percentage

## Cost Optimization

### For Development Environment
- Use B1 or B2 App Service Plan SKU
- Set Log Analytics retention to 7-30 days
- Use Standard ACR SKU
- Regular cleanup of old container images

### Estimated Monthly Costs
- App Service Plan (B2): ~$33
- Container Registry: ~$10
- Application Insights: Included with App Service
- Log Analytics: ~$2-5
- **Total: ~$46/month**

## Best Practices

1. **Environment Separation**: Use separate resource groups for dev/staging/prod
2. **Naming Convention**: Maintain consistent naming across all environments
3. **Parameter Files**: Keep separate parameter files for each environment
4. **Version Control**: Store Bicep templates in Git with version history
5. **Access Control**: Use RBAC roles instead of shared credentials
6. **Monitoring**: Configure alerts for critical metrics
7. **Automated Deployments**: Use GitHub Actions or Azure Pipelines for CI/CD
8. **Regular Testing**: Test disaster recovery and scaling procedures

## Resources

- [Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/)
- [App Service Documentation](https://learn.microsoft.com/en-us/azure/app-service/)
- [Container Registry Documentation](https://learn.microsoft.com/en-us/azure/container-registry/)
- [Application Insights](https://learn.microsoft.com/en-us/azure/azure-monitor/app/app-insights-overview)
- [Managed Identity](https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Azure documentation links
3. Contact the development team
4. Create an issue in the repository

---

**Last Updated**: December 10, 2025  
**Version**: 1.0  
**Status**: Production Ready
