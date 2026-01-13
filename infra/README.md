# ZavaStorefront Infrastructure

This directory contains the Azure infrastructure as code (IaC) using Bicep templates for the ZavaStorefront application.

## Architecture Overview

The infrastructure deploys the following Azure resources:

- **Resource Group**: Logical container for all resources in westus3
- **Azure Container Registry (ACR)**: Stores Docker container images
- **App Service Plan**: Linux-based hosting for containers (B1 SKU for dev)
- **App Service**: Web App for Containers with system-assigned managed identity
- **Application Insights**: Application performance monitoring and diagnostics
- **Log Analytics Workspace**: Centralized logging and analytics
- **Microsoft Foundry**: AI model hosting (GPT-4 and Phi models)
- **Role Assignments**: AcrPull role for App Service to pull from ACR

## Directory Structure

```
infra/
├── main.bicep                    # Main orchestration template
├── main.parameters.json          # Environment-specific parameters
├── modules/
│   ├── acr.bicep                # Container Registry module
│   ├── appservice.bicep         # App Service + Plan module
│   ├── appinsights.bicep        # Application Insights + Log Analytics
│   ├── foundry.bicep            # Microsoft Foundry module
│   └── roleassignments.bicep    # RBAC assignments module
└── README.md                     # This file
```

## Prerequisites

Before deploying, ensure you have:

1. **Azure CLI** installed and authenticated (`az login`)
2. **Azure Developer CLI (azd)** installed
3. **Active Azure subscription** with permissions to create resources
4. **GitHub account** for source code repository

## Deployment Steps

### Option 1: Using Azure Developer CLI (Recommended)

1. **Initialize the project** (first time only):
   ```bash
   azd init
   ```

2. **Preview the deployment**:
   ```bash
   azd provision --preview
   ```

3. **Provision infrastructure and deploy application**:
   ```bash
   azd up
   ```

4. **View deployed resources**:
   ```bash
   azd show
   ```

### Option 2: Using Azure CLI

1. **Validate the template**:
   ```bash
   az deployment sub what-if \
     --location westus3 \
     --template-file infra/main.bicep \
     --parameters infra/main.parameters.json
   ```

2. **Deploy the infrastructure**:
   ```bash
   az deployment sub create \
     --name zavastore-deployment \
     --location westus3 \
     --template-file infra/main.bicep \
     --parameters infra/main.parameters.json
   ```

3. **Build and push Docker image** (no local Docker required):
   ```bash
   # Get ACR name from deployment output
   ACR_NAME=$(az deployment sub show \
     --name zavastore-deployment \
     --query properties.outputs.acrName.value -o tsv)
   
   # Build in Azure Container Registry
   az acr build \
     --registry $ACR_NAME \
     --image zavastore:latest \
     --file Dockerfile \
     ./src
   ```

4. **Update App Service to use the new image**:
   ```bash
   # Get App Service name
   APP_NAME=$(az deployment sub show \
     --name zavastore-deployment \
     --query properties.outputs.appServiceName.value -o tsv)
   
   # Get resource group name
   RG_NAME=$(az deployment sub show \
     --name zavastore-deployment \
     --query properties.outputs.resourceGroupName.value -o tsv)
   
   # Update App Service configuration
   az webapp config container set \
     --name $APP_NAME \
     --resource-group $RG_NAME \
     --docker-custom-image-name "${ACR_NAME}.azurecr.io/zavastore:latest"
   ```

## Configuration Parameters

You can customize the deployment by modifying [main.parameters.json](./main.parameters.json):

| Parameter | Description | Default | Allowed Values |
|-----------|-------------|---------|----------------|
| `environmentName` | Environment name (dev/staging/prod) | `dev` | String (1-10 chars) |
| `location` | Azure region | `westus3` | Valid Azure region |
| `resourceBaseName` | Base name for resources | `zavastore` | String |
| `acrSku` | Container Registry SKU | `Basic` | Basic, Standard, Premium |
| `appServicePlanSku` | App Service Plan SKU | `B1` | B1-B3, S1-S3, P1v2-P3v2 |
| `dockerImageName` | Initial Docker image | Hello World image | Valid Docker image |

## Security Features

- **No admin credentials**: ACR admin user is disabled
- **Managed Identity**: App Service uses system-assigned identity for ACR access
- **RBAC**: AcrPull role assigned with least privilege principle
- **HTTPS only**: App Service enforces HTTPS connections
- **TLS 1.2+**: Minimum TLS version enforced
- **Anonymous pull disabled**: Authentication required for all ACR operations

## Cost Optimization

Estimated monthly costs for dev environment:

- App Service Plan (B1): ~$13/month
- Container Registry (Basic): ~$5/month
- Application Insights: ~$2-5/month (pay-as-you-go)
- Log Analytics (Free tier): $0 (first 5GB)
- Microsoft Foundry: Variable (pay-per-use)

**Total**: ~$20-25/month (excluding AI model usage)

## Monitoring

Access monitoring dashboards:

1. **Application Insights**: View in Azure Portal
   ```bash
   az portal show --resource-group <rg-name> --resource <appinsights-name>
   ```

2. **Log Analytics**: Query logs using KQL
   ```bash
   az monitor log-analytics query \
     --workspace <workspace-id> \
     --analytics-query "requests | take 10"
   ```

## CI/CD Integration

The infrastructure is designed to work with GitHub Actions:

1. Store Azure credentials as GitHub secrets
2. Use the workflow templates in `.github/workflows/`
3. Automated builds use `az acr build` (no local Docker needed)
4. Deployments update App Service with new container images

## Cleanup

To delete all resources:

```bash
# Using azd
azd down

# Using Azure CLI
az group delete --name <resource-group-name> --yes
```

## Troubleshooting

### Issue: ACR image pull fails

**Solution**: Verify role assignment:
```bash
az role assignment list \
  --assignee <app-service-principal-id> \
  --scope <acr-resource-id>
```

### Issue: App Service doesn't start

**Solution**: Check logs:
```bash
az webapp log tail --name <app-name> --resource-group <rg-name>
```

### Issue: Application Insights not receiving data

**Solution**: Verify connection string in App Service settings:
```bash
az webapp config appsettings list \
  --name <app-name> \
  --resource-group <rg-name>
```

## Additional Resources

- [Azure App Service Documentation](https://learn.microsoft.com/azure/app-service/)
- [Azure Container Registry Documentation](https://learn.microsoft.com/azure/container-registry/)
- [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Application Insights Documentation](https://learn.microsoft.com/azure/azure-monitor/app/app-insights-overview)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Azure service health status
3. Consult Microsoft Learn documentation
4. Open an issue in the GitHub repository
