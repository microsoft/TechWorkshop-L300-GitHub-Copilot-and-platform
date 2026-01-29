# ZavaStorefront Infrastructure

This directory contains Bicep templates for deploying the ZavaStorefront application infrastructure to Azure.

## Overview

The infrastructure is designed for the ZavaStorefront containerized web application with the following components:

- **Azure Container Registry (ACR)** - Stores container images
- **Azure App Service** - Hosts the containerized web application (Linux)
- **Application Insights** - Application monitoring and telemetry
- **Log Analytics Workspace** - Centralized logging
- **Microsoft Foundry** - AI services (GPT-4, Phi models)
- **RBAC Role Assignments** - Secure access using managed identities

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Resource Group (westus3)                  │
│                                                              │
│  ┌──────────────┐      ┌─────────────────┐                │
│  │     ACR      │◄─────│   App Service   │                │
│  │   (Images)   │      │  (Web App for   │                │
│  └──────────────┘      │   Containers)   │                │
│         ▲              └────────┬────────┘                │
│         │                       │                          │
│         │ AcrPull              │                          │
│         │ (Managed Identity)   │                          │
│         │                      ▼                          │
│  Cloud Build          ┌──────────────────┐               │
│  (az acr build)       │ App Insights +   │               │
│                       │ Log Analytics    │               │
│                       └──────────────────┘               │
│                                                            │
│  ┌──────────────────────────────┐                        │
│  │   Microsoft Foundry          │                        │
│  │   (AI Services)              │                        │
│  │   - GPT-4                    │                        │
│  │   - Phi-3                    │                        │
│  └──────────────────────────────┘                        │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

1. **Azure CLI** - [Install](https://learn.microsoft.com/cli/azure/install-azure-cli)
2. **Azure Developer CLI (azd)** - [Install](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd)
3. **Bicep CLI** - Installed with Azure CLI
4. **Azure Subscription** - With appropriate permissions
5. **Microsoft Foundry quota** - Verify quota in westus3 region

## Deployment

### Option 1: Using Azure Developer CLI (Recommended)

1. **Initialize the environment:**
   ```bash
   azd init
   ```

2. **Login to Azure:**
   ```bash
   azd auth login
   ```

3. **Provision infrastructure:**
   ```bash
   azd provision
   ```

4. **Deploy application:**
   ```bash
   azd deploy
   ```

### Option 2: Using Azure CLI with Bicep

1. **Login to Azure:**
   ```bash
   az login
   ```

2. **Set your subscription:**
   ```bash
   az account set --subscription <subscription-id>
   ```

3. **Deploy infrastructure:**
   ```bash
   az deployment sub create \
     --location westus3 \
     --template-file infra/main.bicep \
     --parameters infra/main.bicepparam
   ```

4. **Build and push container image:**
   ```bash
   az acr build \
     --registry <acr-name> \
     --image zavastore:latest \
     ./src
   ```

## File Structure

```
infra/
├── main.bicep                    # Main orchestration template
├── main.bicepparam               # Parameters for dev environment
├── README.md                     # This file
└── modules/
    ├── containerRegistry.bicep   # Azure Container Registry
    ├── appService.bicep          # App Service Plan + Web App
    ├── appInsights.bicep         # Application Insights + Log Analytics
    ├── foundry.bicep             # Microsoft Foundry (AI Services)
    └── roleAssignments.bicep     # RBAC role assignments
```

## Parameters

### Main Parameters (main.bicepparam)

| Parameter | Default | Description |
|-----------|---------|-------------|
| `environmentName` | `dev` | Environment identifier |
| `location` | `westus3` | Azure region |
| `appName` | `zavastore` | Application base name |
| `acrSku` | `Basic` | ACR pricing tier |
| `appServicePlanSku` | `B1` | App Service Plan SKU |
| `foundrySku` | `S0` | Microsoft Foundry SKU |

### Customization

Edit [main.bicepparam](./main.bicepparam) to customize parameters for your environment.

## Outputs

After successful deployment, the following outputs are available:

| Output | Description |
|--------|-------------|
| `AZURE_RESOURCE_GROUP` | Resource group name |
| `AZURE_CONTAINER_REGISTRY_NAME` | ACR name |
| `AZURE_CONTAINER_REGISTRY_ENDPOINT` | ACR login server |
| `AZURE_APP_SERVICE_NAME` | Web App name |
| `AZURE_APP_SERVICE_URL` | Application URL |
| `APPINSIGHTS_INSTRUMENTATIONKEY` | App Insights key |
| `AZURE_FOUNDRY_ENDPOINT` | Foundry endpoint |

View outputs:
```bash
az deployment sub show \
  --name <deployment-name> \
  --query properties.outputs
```

Or with azd:
```bash
azd env get-values
```

## Security Features

### Managed Identity

- **System-assigned managed identity** enabled on App Service
- **No password-based authentication** to ACR
- **AcrPull role** automatically assigned

### Network Security

- **HTTPS only** enforced
- **Minimum TLS version** 1.2
- **FTPS disabled**

### Application Insights

- **Instrumentation key** configured automatically
- **Connection string** set in app settings

## Container Deployment

### Cloud-Based Build (No Local Docker)

Build and push directly to ACR using cloud builders:

```bash
az acr build \
  --registry <acr-name> \
  --image zavastore:latest \
  --image zavastore:$(git rev-parse HEAD) \
  ./src
```

### GitHub Actions Integration

Add to your workflow:

```yaml
- name: Build and Push to ACR
  run: |
    az acr build \
      --registry ${{ vars.AZURE_CONTAINER_REGISTRY_NAME }} \
      --image zavastore:${{ github.sha }} \
      --image zavastore:latest \
      ./src
```

## Monitoring

### Application Insights

View telemetry in Azure Portal:
```
https://portal.azure.com -> Application Insights -> <app-name>
```

### Log Analytics

Query logs using KQL:
```bash
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query "AppTraces | limit 50"
```

### App Service Logs

Stream live logs:
```bash
az webapp log tail \
  --name <app-name> \
  --resource-group <rg-name>
```

## Cost Estimation

| Resource | SKU/Tier | Monthly Cost (approx.) |
|----------|----------|------------------------|
| ACR | Basic | $5 |
| App Service Plan | B1 | $13 |
| Application Insights | Pay-as-you-go | $2-5 |
| Log Analytics | PerGB2018 | $2-5 |
| Microsoft Foundry | S0 | Variable (usage-based) |

**Total**: ~$22-30/month (excluding Foundry usage)

## Troubleshooting

### Deployment Fails

1. Check Azure CLI version: `az --version`
2. Verify subscription access: `az account show`
3. Review deployment errors: `az deployment sub show --name <deployment-name>`

### Container Pull Fails

1. Verify managed identity: `az webapp identity show --name <app-name>`
2. Check role assignment: `az role assignment list --assignee <principal-id>`
3. Ensure ACR admin is disabled

### Application Insights Not Working

1. Verify instrumentation key: `az webapp config appsettings list --name <app-name>`
2. Check Application Insights resource: `az monitor app-insights component show --app <app-name>`

## Clean Up

### Using azd
```bash
azd down
```

### Using Azure CLI
```bash
az group delete --name <resource-group-name> --yes
```

## Next Steps

1. Configure custom domain for App Service
2. Set up staging slots for blue/green deployments
3. Enable auto-scaling rules
4. Configure alerts and monitoring dashboards
5. Integrate with Key Vault for secrets management
6. Set up backup and disaster recovery

## Related Resources

- [Azure App Service Documentation](https://learn.microsoft.com/azure/app-service/)
- [Azure Container Registry](https://learn.microsoft.com/azure/container-registry/)
- [Application Insights](https://learn.microsoft.com/azure/azure-monitor/app/app-insights-overview)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/)

## Support

For issues related to:
- **Infrastructure templates**: Open an issue in this repository
- **Azure services**: [Azure Support](https://azure.microsoft.com/support/)
- **Bicep language**: [Bicep GitHub](https://github.com/Azure/bicep)
