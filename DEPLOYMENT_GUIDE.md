# ZavaStorefront Infrastructure Deployment Guide

## Quick Start

### 1. Deploy with Azure Developer CLI (azd)

```bash
# Login to Azure
az login

# Preview the deployment
azd provision --preview

# Deploy everything
azd up

# The deployment will:
# - Create all Azure resources
# - Build the Docker image in Azure (no local Docker needed)
# - Deploy the application to App Service
```

### 2. Build and Push Docker Image (Manual)

If you need to manually build and push the image:

```bash
# Get the ACR name from deployment output
export ACR_NAME=$(az deployment sub show \
  --name zavastore-deployment \
  --query properties.outputs.acrName.value -o tsv)

# Build in Azure Container Registry (no local Docker required)
az acr build \
  --registry $ACR_NAME \
  --image zavastore:latest \
  --file Dockerfile \
  ./src
```

### 3. Access Your Application

After deployment completes:

```bash
# Get the application URL
az deployment sub show \
  --name zavastore-deployment \
  --query properties.outputs.appServiceUrl.value -o tsv
```

## File Structure Created

```
.
├── azd.yaml                      # Azure Developer CLI configuration
├── Dockerfile                    # Container definition for .NET 6.0 app
└── infra/
    ├── README.md                 # Detailed infrastructure documentation
    ├── main.bicep               # Main orchestration template
    ├── main.parameters.json     # Environment parameters
    └── modules/
        ├── acr.bicep            # Container Registry
        ├── appinsights.bicep    # Monitoring & logging
        ├── appservice.bicep     # Web app hosting
        ├── foundry.bicep        # AI model hosting
        └── roleassignments.bicep # Security permissions
```

## Key Features

✅ **No Local Docker Required** - Builds happen in Azure  
✅ **Secure by Design** - Managed identities, no passwords  
✅ **Cost Optimized** - ~$20-25/month for dev environment  
✅ **Production Ready** - Easy to scale up when needed  
✅ **Full Monitoring** - Application Insights integrated  
✅ **AI Enabled** - Microsoft Foundry for GPT-4 & Phi models

## Next Steps

1. **Customize parameters**: Edit `infra/main.parameters.json`
2. **Set up CI/CD**: Create GitHub Actions workflow
3. **Monitor**: Check Application Insights dashboard
4. **Scale**: Upgrade SKUs in parameters when ready for production

## Resources

- [Full Infrastructure README](./infra/README.md)
- [Azure App Service Docs](https://learn.microsoft.com/azure/app-service/)
- [Azure Developer CLI Docs](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
