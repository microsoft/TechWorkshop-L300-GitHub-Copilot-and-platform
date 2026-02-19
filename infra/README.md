# ZavaStorefront Infrastructure

This directory contains the Azure infrastructure-as-code (IaC) for the ZavaStorefront web application, implemented using Bicep and deployable via Azure Developer CLI (AZD).

## Architecture Overview

The infrastructure provisions a complete development environment in Azure with the following components:

### Core Resources
- **Resource Group**: Single resource group in `westus3` for all resources
- **Azure Container Registry (ACR)**: Stores Docker images for the application (Basic SKU)
- **App Service Plan**: Linux-based plan (B1 SKU for dev)
- **App Service**: Web App for Containers, configured to pull images from ACR
- **Log Analytics Workspace**: Centralized logging and monitoring
- **Application Insights**: Application performance monitoring (APM)
- **Microsoft Foundry (AI Hub)**: AI services with GPT-4 and Phi model access
- **Storage Account**: Required for AI Hub (Standard_LRS)
- **Key Vault**: Secrets management for AI Hub (Standard SKU)

### Security Features
- **Azure RBAC**: App Service uses system-assigned managed identity with AcrPull role for secure image pulls
- **No Passwords**: ACR admin credentials disabled; all access via managed identities
- **HTTPS Only**: App Service configured for HTTPS traffic only
- **TLS 1.2+**: Minimum TLS version enforced on all services

## Resource Naming Conventions

Resources follow Azure naming best practices with the pattern:
```
{resource-type-abbr}-{app-name}-{environment}-{location}[-{unique-suffix}]
```

Examples:
- Resource Group: `rg-zavastore-dev-westus3`
- App Service: `app-zavastore-dev-westus3`
- ACR: `crzavastoredev{uniqueId}` (no hyphens allowed)
- AI Hub: `aih-zavastore-dev-westus3`

All resources are tagged with:
- `environment`: dev, staging, or prod
- `application`: ZavaStorefront
- `managedBy`: Bicep

## Prerequisites

1. **Azure CLI** - Install from https://docs.microsoft.com/cli/azure/install-azure-cli
2. **Azure Developer CLI (AZD)** - Install from https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd
3. **Active Azure Subscription** with permissions to create resources
4. **Bicep** - Automatically installed with Azure CLI

Verify installations:
```bash
az --version
azd version
```

## Deployment

### Step 1: Login to Azure
```bash
az login
azd auth login
```

### Step 2: Initialize AZD (First time only)
```bash
azd init
```

Follow the prompts to:
- Confirm the detected .NET application
- Set environment name (e.g., `dev`, `staging`)

### Step 3: Preview Infrastructure
Preview what resources will be created without actually deploying:
```bash
azd provision --preview
```

You'll be prompted to select:
- Azure subscription
- Resource group (existing or new)
- Region (default: westus3)

### Step 4: Deploy Infrastructure
Deploy all Azure resources:
```bash
azd up
```

This command will:
1. Package the application
2. Provision all Azure resources via Bicep
3. Build the Docker image in ACR (no local Docker required)
4. Deploy the application to App Service

**Note**: First deployment typically takes 10-15 minutes.

### Alternative: Deploy in Stages
If you prefer to deploy infrastructure and application separately:

```bash
# Provision infrastructure only
azd provision

# Build and deploy application (after infrastructure is ready)
azd deploy
```

## Building Images Without Local Docker

You don't need Docker installed locally. Azure provides cloud-based image builds:

### Method 1: Using AZD (Recommended)
```bash
azd deploy
```
AZD automatically builds the image in ACR and deploys to App Service.

### Method 2: Using Azure CLI
```bash
# Build image directly in ACR (cloud-side build)
az acr build --registry <acr-name> --image zavastore:latest --file ../Dockerfile ../src

# Update App Service to use the new image
az webapp config container set \
  --name <app-service-name> \
  --resource-group <resource-group-name> \
  --docker-custom-image-name <acr-name>.azurecr.io/zavastore:latest
```

### Method 3: Using GitHub Actions
See the `.github/workflows` directory for CI/CD pipeline examples that build and deploy automatically on push.

## Managing the Infrastructure

### View Deployed Resources
```bash
azd show
```

### View Environment Variables
```bash
azd env get-values
```

### Update Infrastructure
After modifying Bicep files:
```bash
azd provision
```

### Redeploy Application Only
```bash
azd deploy
```

### View Application Logs
```bash
azd monitor
```

Or use Azure CLI:
```bash
az webapp log tail --name <app-service-name> --resource-group <resource-group-name>
```

## Accessing Services

### App Service
After deployment, access your application at:
```
https://<app-service-name>.azurewebsites.net
```

The URL is displayed in the `azd up` output.

### Application Insights
View monitoring data in Azure Portal:
1. Navigate to your Resource Group
2. Open the Application Insights resource
3. Explore metrics, logs, and performance data

### AI Hub (Microsoft Foundry)
Access AI services and models:
1. Navigate to your Resource Group in Azure Portal
2. Open the AI Hub resource
3. Configure model deployments for GPT-4 and Phi

**Important**: Ensure your subscription has quota for AI models in westus3.

## Cost Considerations

This development environment uses cost-optimized SKUs:

| Resource | SKU | Estimated Monthly Cost |
|----------|-----|------------------------|
| App Service Plan | B1 (Basic) | ~$13 USD |
| ACR | Basic | ~$5 USD |
| Log Analytics | Pay-as-you-go | ~$2-5 USD |
| Application Insights | Pay-as-you-go | ~$0-5 USD |
| Storage Account | Standard_LRS | ~$1-2 USD |
| Key Vault | Standard | ~$0-1 USD |
| AI Hub | Basic | Variable (pay-per-use) |

**Total estimated**: ~$20-30 USD/month (excluding AI model usage)

**Cost Optimization Tips**:
- Delete resources when not in use: `azd down --purge`
- Use auto-shutdown for App Service during non-working hours
- Monitor AI model usage carefully (most expensive component)

## Cleanup

### Delete All Resources
```bash
azd down --purge
```

This removes:
- All Azure resources in the resource group
- The AZD environment configuration

**Warning**: This action is irreversible. Ensure you've backed up any data.

### Keep Infrastructure, Remove Application
```bash
azd deploy --force
```

## Troubleshooting

### Issue: Deployment Fails with Quota Error
**Solution**: Check your subscription quotas and request increases if needed:
```bash
az vm list-usage --location westus3 -o table
```

### Issue: ACR Pull Fails
**Solution**: Verify managed identity has AcrPull role:
```bash
az role assignment list --scope /subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.ContainerRegistry/registries/{acr-name}
```

### Issue: AI Hub Models Not Available
**Solution**: Verify westus3 supports your desired models:
- Check [AI Foundry region support documentation](https://learn.microsoft.com/azure/ai-foundry/reference/region-support)
- Consider using alternative region if models aren't available

### Issue: App Service Doesn't Start
**Solution**: Check container logs:
```bash
az webapp log tail --name <app-service-name> --resource-group <resource-group-name>
```

Common causes:
- Image not found in ACR
- Missing environment variables
- Application startup errors

## Bicep Module Structure

```
infra/
├── main.bicep                    # Main orchestration template
├── main.parameters.json          # Parameter overrides (optional)
├── modules/
│   ├── acr.bicep                 # Azure Container Registry
│   ├── appService.bicep          # App Service (Web App)
│   ├── appServicePlan.bicep      # App Service Plan
│   ├── appInsights.bicep         # Application Insights
│   ├── logAnalytics.bicep        # Log Analytics Workspace
│   ├── storageAccount.bicep      # Storage Account (for AI Hub)
│   ├── keyVault.bicep            # Key Vault (for AI Hub)
│   ├── aiHub.bicep               # Microsoft Foundry AI Hub
│   └── roleAssignment.bicep      # RBAC role assignments
└── README.md                     # This file
```

## Development Workflow

1. **Local Development**: Develop and test application locally using `dotnet run`
2. **Code Changes**: Make changes and commit to your branch
3. **Preview Infra**: Run `azd provision --preview` to validate changes
4. **Deploy**: Run `azd up` to deploy changes to Azure
5. **Monitor**: Use Application Insights to monitor performance
6. **Iterate**: Repeat steps 1-5 as needed

## CI/CD Integration

For automated deployments, integrate with GitHub Actions or Azure Pipelines:

### GitHub Actions Example
See `.github/workflows/deploy.yml` for a complete CI/CD pipeline that:
- Builds on every push to main
- Runs tests
- Builds Docker image in ACR
- Deploys to App Service
- All without local Docker installation

## Additional Resources

- [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [App Service for Containers](https://learn.microsoft.com/azure/app-service/configure-custom-container)
- [Azure Container Registry](https://learn.microsoft.com/azure/container-registry/)
- [Microsoft Foundry (AI Hub)](https://learn.microsoft.com/azure/ai-foundry/)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Azure Portal activity logs
3. Check Application Insights for application errors
4. Review AZD logs: `.azure/<environment-name>/logs/`

---

**Environment**: Development  
**Region**: West US 3  
**Deployment Method**: Azure Developer CLI (AZD) + Bicep  
**Last Updated**: 2026-02-19
