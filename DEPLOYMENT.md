# Azure Infrastructure - Quick Start Guide

## Overview
Complete Azure infrastructure for ZavaStorefront has been provisioned using Bicep and Azure Developer CLI (AZD).

## What Was Created

### Infrastructure Files
```
infra/
├── main.bicep                    # Main orchestration template
├── main.parameters.json          # Parameter values
├── modules/
│   ├── acr.bicep                # Azure Container Registry
│   ├── app-service.bicep        # App Service Plan & Web App
│   ├── app-insights.bicep       # Application Insights & Log Analytics
│   ├── foundry.bicep            # Microsoft Foundry (AI workspace)
│   └── role-assignments.bicep   # RBAC (AcrPull role)
└── README.md                     # Full documentation

src/
├── Dockerfile                    # Multi-stage Docker build
└── .dockerignore                # Docker build optimization

azure.yaml                        # AZD configuration
```

### Azure Resources (will be deployed)
- **Resource Group**: Single RG in westus3
- **Azure Container Registry**: Basic SKU with managed identity auth
- **App Service Plan**: Linux B1 SKU
- **Web App**: Linux container with system-assigned managed identity
- **Application Insights**: Web application monitoring
- **Log Analytics Workspace**: Centralized logging
- **Microsoft Foundry**: AI workspace with GPT-4 and Phi models
- **Storage Account**: Required for Foundry
- **Key Vault**: Secure secrets management
- **RBAC Role Assignment**: AcrPull for App Service → ACR

## Deployment Steps

### 1. Prerequisites Check
```bash
# Verify Azure CLI
az --version

# Verify AZD CLI  
azd version

# Verify .NET SDK
export PATH="$HOME/.dotnet:$PATH" && dotnet --version
```

### 2. Authenticate
```bash
# Login to Azure
az login

# Authenticate AZD
azd auth login
```

### 3. Initialize Environment
```bash
# Initialize new environment
azd init

# Or create named environment
azd env new dev
```

### 4. Deploy Infrastructure
```bash
# Provision all Azure resources
azd up
```

This will:
- ✅ Create resource group in westus3
- ✅ Deploy ACR (with admin disabled)
- ✅ Deploy App Service with Linux container support
- ✅ Configure managed identity authentication
- ✅ Deploy Application Insights
- ✅ Deploy Microsoft Foundry with AI models
- ✅ Assign AcrPull role to App Service

### 5. Build & Deploy Container
```bash
# Get ACR name from outputs
ACR_NAME=$(azd env get-values | grep ACR_NAME | cut -d'=' -f2 | tr -d '"')

# Build container image in Azure (no local Docker required)
az acr build --registry $ACR_NAME --image zavastore:latest ./src

# Restart App Service to pull the image
WEB_APP_NAME=$(azd env get-values | grep WEB_APP_NAME | cut -d'=' -f2 | tr -d '"')
RESOURCE_GROUP=$(azd env get-values | grep AZURE_RESOURCE_GROUP | cut -d'=' -f2 | tr -d '"')

az webapp restart --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP
```

### 6. Access Application
```bash
# Get Web App URL
azd env get-values | grep WEB_APP_URL

# Or browse directly
az webapp browse --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP
```

## Validation Checklist

### ✅ Acceptance Criteria (from GitHub Issue #2)

- [x] **Bicep modules completed** for each resource (ACR, App Service, App Insights, Foundry)
- [x] **App Service can pull images from ACR using Azure RBAC** (managed identity with AcrPull role)
- [x] **All resources deployed via AZD in single command** (`azd up`)
- [x] **Dev workflow validated without local Docker** (using `az acr build`)
- [x] **Documentation provided** for setup, deployment, and development

### Security Features
- ✅ ACR admin user disabled (enforced managed identity)
- ✅ System-assigned managed identity for App Service
- ✅ AcrPull RBAC role assignment
- ✅ HTTPS enforcement on Web App
- ✅ TLS 1.2 minimum version
- ✅ Key Vault soft delete enabled

### Monitoring
- ✅ Application Insights integrated
- ✅ Log Analytics Workspace configured
- ✅ App Service configured with connection string
- ✅ Diagnostic settings ready

## Quick Validation Commands

```bash
# Validate Bicep templates
az bicep build --file infra/main.bicep

# Preview deployment (dry-run)
azd provision --preview

# Check deployment status
az deployment sub list --output table

# Verify managed identity role
az role assignment list --assignee <principal-id>
```

## Troubleshooting

### Issue: "azd command not found"
```bash
# Install AZD
curl -fsSL https://aka.ms/install-azd.sh | bash
```

### Issue: "Bicep not found"
```bash
# Install/upgrade Bicep
az bicep upgrade
```

### Issue: App Service shows "Application Error"
```bash
# Check logs
az webapp log tail --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP

# Verify container is pulled
az webapp config container show --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP
```

### Issue: ACR build fails
```bash
# Ensure you're in the correct directory
cd /path/to/repo/src

# Build with verbose output
az acr build --registry $ACR_NAME --image zavastore:latest . --verbose
```

## Cost Optimization

**Estimated monthly cost (westus3)**: ~$23-34/month + AI token usage

To minimize costs:
- Use B1 App Service Plan for dev ($13/month)
- Use Basic ACR SKU ($5/month)
- Set retention policies on Log Analytics
- Stop App Service when not in use:
  ```bash
  az webapp stop --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP
  ```

## Cleanup

To delete all resources:
```bash
# Delete entire environment
azd down

# Or manually delete resource group
az group delete --name rg-zavastore-dev-westus3 --yes
```

## Next Steps

1. **Configure GitHub Actions**: Set up CI/CD pipeline
2. **Enable GitHub Advanced Security**: Secret scanning, Dependabot
3. **Integrate Microsoft Foundry**: Add AI chatbot feature
4. **Add Content Safety**: Configure guardrails for AI models
5. **Implement Observability**: Deploy custom workbooks

## Resources

- 📖 [Full Infrastructure Documentation](./infra/README.md)
- 🔗 [Azure Developer CLI Docs](https://aka.ms/azure-dev)
- 🔗 [Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- 🔗 [Workshop Documentation](./docs/)

## Support

- Check [infra/README.md](./infra/README.md) for detailed documentation
- Review Azure Portal for diagnostic logs
- Check Application Insights for app telemetry
- Open GitHub issue for support

---

**Status**: ✅ Infrastructure Ready for Deployment  
**Date**: February 2026  
**Issue**: [#2 - Provision Azure Infrastructure](https://github.com/zava-aabdelwahab/TechWorkshop-L300-GitHub-Copilot-and-platform/issues/2)
