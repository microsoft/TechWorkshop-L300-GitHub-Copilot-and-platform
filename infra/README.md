# Azure Infrastructure for Zava Storefront

This infrastructure deployment creates all necessary Azure resources to run the Zava Storefront .NET application as a containerized web app.

## Architecture Overview

The infrastructure includes the following Azure resources:

- **Resource Group**: Container for all related resources
- **Azure Container Registry (ACR)**: Stores Docker images
- **App Service Plan**: Linux-based hosting plan for containers
- **App Service**: Web application host configured for containers
- **Application Insights**: Application performance monitoring
- **Log Analytics Workspace**: Centralized logging and analytics
- **Microsoft Foundry**: AI platform for GPT-4 and Phi models
- **Role Assignments**: Managed identity permissions for ACR access

## Security Features

- **Managed Identity**: App Service uses system-assigned managed identity
- **No Admin Passwords**: ACR access through RBAC (AcrPull role)
- **HTTPS Only**: All traffic forced to HTTPS
- **TLS 1.2 Minimum**: Modern encryption standards
- **Disabled FTP**: Enhanced security posture

## Prerequisites

Before deploying this infrastructure, ensure you have:

1. **Azure CLI** installed and authenticated
2. **Azure Developer CLI (azd)** installed
3. **Docker** (optional - can use cloud builds)
4. **Appropriate Azure permissions** in the target subscription

## Deployment Instructions

### Step 1: Initialize Azure Developer CLI

```bash
cd <project-root>
azd init
```

Select the default option to scan the current directory and configure the .NET application.

### Step 2: Preview the Deployment

```bash
azd provision --preview
```

This will show you what resources will be created without actually deploying them.

### Step 3: Deploy Infrastructure

```bash
azd provision
```

You'll be prompted for:
- **Environment name** (e.g., dev, test, prod)
- **Azure subscription** (if multiple are available)
- **Azure region** (recommended: westus3 for Microsoft Foundry support)

### Step 4: Deploy Application

```bash
azd deploy
```

This will:
1. Build the Docker image using `az acr build`
2. Push the image to Azure Container Registry
3. Update the App Service to use the new image

### Step 5: Complete Deployment

```bash
azd up
```

This combines both provision and deploy steps in one command.

## Resource Naming Convention

Resources follow this naming pattern:
- Resource Group: `rg-{appName}-{env}-{location}`
- App Service: `app-{appName}-{env}-{uniqueId}`
- Container Registry: `acr{uniqueId}{appName}{env}`
- App Insights: `appi-{appName}-{env}-{location}`

Where:
- `{appName}` = zavastore
- `{env}` = environment name (dev, test, prod)
- `{location}` = Azure region
- `{uniqueId}` = generated unique identifier

## Environment Variables

The App Service is configured with these environment variables:

| Variable | Purpose |
|----------|---------|
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | Application Insights telemetry |
| `ASPNETCORE_ENVIRONMENT` | ASP.NET Core environment setting |
| `WEBSITES_PORT` | Container port (8080) |
| `DOCKER_REGISTRY_SERVER_URL` | ACR login server URL |

## Monitoring and Observability

### Application Insights
- Automatic request tracking
- Dependency monitoring
- Exception logging
- Custom telemetry support

### Log Analytics
- Centralized log collection
- Query capabilities with KQL
- Integration with Application Insights
- 30-day retention (configurable)

## Cost Optimization

The infrastructure uses cost-effective SKUs suitable for development:

- **App Service Plan**: B1 (Basic)
- **Container Registry**: Basic
- **Log Analytics**: Pay-per-GB
- **Application Insights**: Usage-based pricing

Estimated monthly cost: $25-50 USD (varies by usage)

## Troubleshooting

### Common Issues

1. **Container Registry Access Denied**
   - Verify managed identity role assignment
   - Check that AcrPull role is assigned correctly

2. **Application Not Starting**
   - Check WEBSITES_PORT matches Docker EXPOSE port
   - Verify Application Insights connection string
   - Review App Service logs in Azure portal

3. **Image Pull Failures**
   - Ensure Docker image exists in ACR
   - Verify image tag matches deployment configuration
   - Check ACR authentication settings

### Useful Commands

```bash
# Check deployment status
azd show

# View application logs
az webapp log tail --name <app-name> --resource-group <rg-name>

# List ACR repositories
az acr repository list --name <acr-name>

# Restart App Service
az webapp restart --name <app-name> --resource-group <rg-name>
```

## Security Considerations

- All resources use managed identities where possible
- Network access is restricted to necessary services only
- Regular security updates should be applied to base images
- Application secrets should be stored in Azure Key Vault (future enhancement)

## Future Enhancements

Consider these improvements for production deployments:

1. **Azure Key Vault** for secrets management
2. **Virtual Network** integration for network isolation
3. **Azure Front Door** for global load balancing
4. **Auto-scaling** configuration for App Service
5. **Azure SQL Database** for persistent data storage
6. **Azure Cache for Redis** for session management

## Support

For issues with this infrastructure:

1. Check Azure portal resource health
2. Review deployment logs in Azure DevOps/GitHub Actions
3. Consult Application Insights for application-specific issues
4. Use `azd` troubleshooting commands for deployment problems