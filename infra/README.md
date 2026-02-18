# ZavaStorefront Infrastructure

This directory contains the Azure infrastructure-as-code (IaC) using Bicep templates for deploying the ZavaStorefront web application.

## Overview

The infrastructure provisions the following Azure resources in the **westus3** region:

- **Resource Group**: Container for all resources
- **Azure Container Registry (ACR)**: Store Docker container images
- **App Service Plan**: Linux-based hosting plan (Basic B1)
- **App Service**: Web app configured for Docker container deployment
- **Application Insights**: Application performance monitoring
- **Log Analytics Workspace**: Centralized logging
- **Storage Account**: Required for AI Foundry
- **Key Vault**: Secure secrets management for AI Foundry
- **AI Hub**: Microsoft Foundry AI Hub for GPT-4 and Phi models
- **AI Project**: Microsoft Foundry AI Project workspace

## Prerequisites

Before deploying, ensure you have:

1. **Azure CLI** installed ([Install Guide](https://learn.microsoft.com/cli/azure/install-azure-cli))
2. **Azure Developer CLI (azd)** installed ([Install Guide](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd))
3. An active **Azure subscription**
4. Appropriate **permissions** to create resources in your subscription

## Quick Start

### 1. Login to Azure

```bash
azd auth login
az login
```

### 2. Initialize the environment

```bash
azd env new
```

You'll be prompted to provide:
- **Environment name**: A unique name for your deployment (e.g., `dev`, `test`, `myname-dev`)
- **Azure location**: Use `westus3` (required for GPT-4 and Phi model availability)

Alternatively, set environment variables:

```bash
azd env set AZURE_ENV_NAME dev
azd env set AZURE_LOCATION westus3
```

### 3. Provision the infrastructure

Preview the deployment (optional):

```bash
azd provision --preview
```

Deploy the infrastructure:

```bash
azd provision
```

This command will:
- Create a new resource group in westus3
- Deploy all Azure resources using Bicep templates
- Configure RBAC for App Service to pull images from ACR
- Output important resource information

### 4. Deploy the application

Build and deploy the containerized application:

```bash
azd deploy
```

This will:
- Build the Docker image
- Push it to Azure Container Registry
- Update the App Service to use the new image

### 5. Open the application

```bash
azd browse
```

Or retrieve the URL:

```bash
azd env get-values | grep APP_SERVICE_URL
```

## Infrastructure Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Resource Group                           │
│                     (westus3)                                │
│                                                              │
│  ┌──────────────────┐      ┌───────────────────┐           │
│  │  App Service     │◄─────│ App Service Plan  │           │
│  │  (Linux/Docker)  │      │   (Basic B1)      │           │
│  └────────┬─────────┘      └───────────────────┘           │
│           │                                                  │
│           │ RBAC (ACR Pull)                                 │
│           ▼                                                  │
│  ┌──────────────────┐      ┌───────────────────┐           │
│  │      ACR         │      │ App Insights      │           │
│  │  (Container      │      │ (Monitoring)      │           │
│  │   Registry)      │      └─────────┬─────────┘           │
│  └──────────────────┘                │                      │
│                                      │                      │
│                           ┌──────────▼─────────┐            │
│                           │ Log Analytics      │            │
│                           │  Workspace         │            │
│                           └────────────────────┘            │
│                                                              │
│  ┌──────────────────┐      ┌───────────────────┐           │
│  │    AI Hub        │◄─────│  Storage Account  │           │
│  │  (Foundry Hub)   │      │                   │           │
│  └────────┬─────────┘      └───────────────────┘           │
│           │                                                  │
│           │                ┌───────────────────┐            │
│           └────────────────│    Key Vault      │            │
│           │                └───────────────────┘            │
│           ▼                                                  │
│  ┌──────────────────┐                                       │
│  │   AI Project     │                                       │
│  │ (GPT-4, Phi)     │                                       │
│  └──────────────────┘                                       │
└─────────────────────────────────────────────────────────────┘
```

## File Structure

```
infra/
├── main.bicep                    # Root orchestration template
├── main.bicepparam               # Parameters file
└── modules/
    ├── appService.bicep          # App Service configuration
    ├── appServicePlan.bicep      # App Service Plan
    ├── containerRegistry.bicep   # Azure Container Registry
    ├── applicationInsights.bicep # Application Insights
    ├── logAnalytics.bicep        # Log Analytics Workspace
    ├── storageAccount.bicep      # Storage Account for AI
    ├── keyVault.bicep            # Key Vault for AI
    ├── aiHub.bicep               # Microsoft Foundry AI Hub
    ├── aiProject.bicep           # Microsoft Foundry AI Project
    └── acrRoleAssignment.bicep   # RBAC role assignment for ACR
```

## Configuration

### Environment Variables

The deployment uses the following environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `AZURE_ENV_NAME` | Environment name (dev, test, prod) | `dev` |
| `AZURE_LOCATION` | Azure region for deployment | `westus3` |

### Resource Naming Convention

Resources are named using the pattern: `<resource-type>-<environment>-<unique-token>`

Example:
- Resource Group: `rg-dev-abc123`
- App Service: `app-abc123`
- Container Registry: `crabc123`

## Key Features

### 1. **No Local Docker Required**

The deployment uses Azure Container Registry Build Tasks (ACR Tasks) via `azd deploy`, which builds the container image in the cloud. You don't need Docker installed locally.

### 2. **Managed Identity Authentication**

The App Service uses a system-assigned managed identity with ACR Pull role assignment to authenticate to Azure Container Registry. No passwords or connection strings are needed.

### 3. **Microsoft Foundry Integration**

The infrastructure includes Azure AI Foundry (formerly Azure Machine Learning) with support for:
- GPT-4 models
- Phi models
- Custom AI workloads

### 4. **Application Monitoring**

Application Insights is automatically configured with the App Service for:
- Request tracking
- Dependency monitoring
- Exception logging
- Performance metrics

## Outputs

After successful deployment, the following outputs are available:

```bash
azd env get-values
```

Key outputs:
- `AZURE_RESOURCE_GROUP`: Resource group name
- `AZURE_LOCATION`: Deployment region
- `AZURE_CONTAINER_REGISTRY_ENDPOINT`: ACR login server URL
- `AZURE_CONTAINER_REGISTRY_NAME`: ACR name
- `APP_SERVICE_NAME`: App Service name
- `APP_SERVICE_URL`: Application URL
- `APPLICATION_INSIGHTS_CONNECTION_STRING`: App Insights connection string
- `AI_HUB_NAME`: AI Foundry Hub name
- `AI_PROJECT_NAME`: AI Foundry Project name

## Troubleshooting

### Preview the deployment

Before deploying, preview what will be created:

```bash
azd provision --preview
```

### Check deployment logs

View detailed logs during deployment:

```bash
az deployment sub show -n <deployment-name> --query properties.error
```

### Validate Bicep files

```bash
az bicep build -f infra/main.bicep
```

### Common Issues

**Issue**: "Location not supported for resource type"
- **Solution**: Ensure you're using `westus3` region for AI Foundry resources

**Issue**: "ACR pull failed with authentication error"
- **Solution**: Wait a few minutes for RBAC role assignment to propagate, then restart the App Service

**Issue**: "Deployment timeout"
- **Solution**: AI Foundry resources can take 10-15 minutes to provision. Be patient during initial deployment.

## Cleanup

To delete all provisioned resources:

```bash
azd down
```

This will remove:
- The resource group
- All resources within it
- Environment configuration (local only)

To keep environment configuration but remove Azure resources:

```bash
azd down --purge
```

## Additional Commands

### Update infrastructure only

```bash
azd provision
```

### Deploy application only (skip infrastructure)

```bash
azd deploy
```

### View application logs

```bash
azd logs --service web --follow
```

### SSH into the running container (for debugging)

```bash
az webapp ssh --name <app-service-name> --resource-group <resource-group-name>
```

## Security Considerations

- All resources use HTTPS/TLS 1.2+
- App Service uses managed identity (no credentials stored)
- Container registry admin user is disabled
- Key Vault uses RBAC authorization
- Secrets are stored in Key Vault
- Application Insights connection string is marked as secure

## Cost Estimation

Approximate monthly costs (USD) for this infrastructure:

| Resource | Tier | Est. Cost/Month |
|----------|------|-----------------|
| App Service Plan | Basic B1 | ~$13 |
| Container Registry | Basic | ~$5 |
| Application Insights | Pay-as-you-go | ~$2-10 |
| Log Analytics | Pay-as-you-go | ~$2-5 |
| Storage Account | Standard LRS | <$1 |
| Key Vault | Standard | <$1 |
| AI Foundry Hub/Project | Free tier | $0-50 |
| **Total** | | **~$23-85/month** |

> **Note**: Actual costs may vary based on usage, data ingress/egress, and AI model consumption.

## Learn More

- [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Azure Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure App Service Documentation](https://learn.microsoft.com/azure/app-service/)
- [Microsoft Foundry Documentation](https://learn.microsoft.com/azure/ai-foundry/)
- [Azure Container Registry Documentation](https://learn.microsoft.com/azure/container-registry/)

## Support

For issues or questions:
1. Check the [troubleshooting section](#troubleshooting)
2. Review Azure deployment logs
3. Create an issue in the repository
4. Contact your Azure support team

---

**Last Updated**: February 2026  
**Maintained by**: ZavaStorefront Team
