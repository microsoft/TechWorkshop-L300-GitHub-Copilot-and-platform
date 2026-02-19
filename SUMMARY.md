# Azure Infrastructure Summary

## Overview
This repository now includes complete Azure infrastructure-as-code (IaC) for deploying the ZavaStorefront web application to Azure as a development environment.

## What Was Implemented

### 1. Infrastructure as Code (Bicep)
Complete modular Bicep templates for all Azure resources:

**Main Template** (`infra/main.bicep`)
- Subscription-level deployment
- Creates resource group in westus3
- Orchestrates all resource deployments
- Implements proper naming conventions and tagging

**Bicep Modules** (`infra/modules/`)
- `acr.bicep` - Azure Container Registry (Basic SKU, no admin credentials)
- `appServicePlan.bicep` - Linux App Service Plan (B1 SKU)
- `appService.bicep` - Web App for Containers with managed identity
- `logAnalytics.bicep` - Log Analytics Workspace
- `appInsights.bicep` - Application Insights (linked to Log Analytics)
- `storageAccount.bicep` - Storage Account (Standard_LRS for AI Hub)
- `keyVault.bicep` - Key Vault (Standard SKU with RBAC)
- `aiHub.bicep` - Microsoft Foundry/AI Hub for GPT-4 and Phi models
- `roleAssignment.bicep` - RBAC role assignments (AcrPull)

### 2. Docker Configuration
**Dockerfile**
- Multi-stage build for .NET 6 application
- Optimized layer caching
- Production-ready runtime configuration
- Exposes ports 80 and 443

**.dockerignore**
- Excludes unnecessary files from build context
- Reduces image size and build time

### 3. Azure Developer CLI (AZD) Configuration
**azure.yaml**
- Defines application structure
- Maps services to infrastructure
- Configures deployment pipeline
- Host type: App Service (not Container Apps)

### 4. CI/CD Pipeline
**GitHub Actions Workflow** (`.github/workflows/azure-deploy.yml`)
- Triggered on push to main or manual dispatch
- Uses OIDC authentication (no secrets in code)
- Builds Docker image in ACR (cloud-based build)
- Deploys to App Service automatically
- Provides deployment summary

### 5. Documentation
**infra/README.md**
- Comprehensive infrastructure documentation
- Architecture overview and resource descriptions
- Naming conventions and tagging strategy
- Prerequisites and deployment steps
- Cost estimates and optimization tips
- Troubleshooting guide

**DEPLOYMENT.md**
- Step-by-step deployment guide
- Multiple deployment methods (AZD, Azure CLI, GitHub Actions)
- Post-deployment configuration
- Verification steps
- Detailed troubleshooting section
- Cleanup instructions

### 6. Security Features Implemented

**Azure RBAC (No Passwords)**
- App Service uses system-assigned managed identity
- ACR admin credentials disabled
- Managed identity granted AcrPull role on ACR
- Key Vault uses RBAC authorization

**HTTPS and TLS**
- App Service enforces HTTPS only
- Minimum TLS 1.2 on all services
- Secure container image pulls

**Network Security**
- Public network access enabled for dev (can be restricted)
- Azure Services bypass for ACR

**Secret Management**
- Key Vault for sensitive data
- Application Insights connection string via app settings
- No hardcoded secrets

## Resource Naming Convention

All resources follow Azure best practices:
```
{resource-type-abbreviation}-{app-name}-{environment}-{location}[-{unique-suffix}]
```

Examples:
- Resource Group: `rg-zavastore-dev-westus3`
- ACR: `crzavastoredev{uniqueId}` (no hyphens allowed)
- App Service Plan: `asp-zavastore-dev-westus3`
- App Service: `app-zavastore-dev-westus3`
- Log Analytics: `log-zavastore-dev-westus3`
- Application Insights: `appi-zavastore-dev-westus3`
- Storage Account: `stzavastoredev{uniqueId}` (lowercase, no hyphens)
- Key Vault: `kv-zavastore-dev-{uniqueId}` (max 24 chars)
- AI Hub: `aih-zavastore-dev-westus3`

## Tags Applied to All Resources
```json
{
  "environment": "dev",
  "application": "ZavaStorefront",
  "managedBy": "Bicep"
}
```

## Deployment Methods

### Method 1: Azure Developer CLI (Recommended)
One command deployment of infrastructure + application:
```bash
azd up
```

### Method 2: Azure CLI
Manual deployment with more control:
```bash
# Deploy infrastructure
az deployment sub create --location westus3 --template-file infra/main.bicep

# Build image in ACR
az acr build --registry <acr-name> --image zavastore:latest --file ./Dockerfile ./src

# Deploy to App Service
az webapp config container set --name <app-name> --resource-group <rg-name> --docker-custom-image-name <acr>.azurecr.io/zavastore:latest
```

### Method 3: GitHub Actions (CI/CD)
Automated deployment on push to main:
- Requires OIDC configuration (documented in DEPLOYMENT.md)
- Builds image in ACR (no local Docker needed)
- Deploys to App Service automatically

## Key Features

### No Local Docker Required
- Images are built in Azure Container Registry using `az acr build`
- Cloud-based builds eliminate the need for local Docker installation
- CI/CD pipelines use ACR build tasks

### Managed Identity for ACR Access
- App Service has system-assigned managed identity
- Identity granted AcrPull role on ACR at resource level
- Eliminates need for registry credentials or passwords

### Monitoring and Observability
- Application Insights for APM
- Log Analytics for centralized logging
- Automatic instrumentation via connection string
- Live metrics and application map

### AI Capabilities
- Microsoft Foundry (AI Hub) provisioned in westus3
- Supports GPT-4 and Phi models
- Integrated with same Application Insights
- Shared Key Vault and Storage Account

### Development-Optimized
- Cost-effective SKUs (Basic/B1 tier)
- Estimated cost: $20-30 USD/month (excluding AI usage)
- Tagged as dev environment
- Suitable for development and testing

## Deployment Time
- **First deployment**: 10-15 minutes
- **Infrastructure updates**: 5-10 minutes
- **Application redeployment**: 2-5 minutes

## Prerequisites
1. Azure CLI (2.50.0+)
2. Azure Developer CLI (1.5.0+)
3. Active Azure subscription
4. Permissions to create resources
5. Quota for AI Hub in westus3 (if using AI features)

## Validation Completed

✅ **Bicep Templates**
- All templates pass `az bicep build` validation
- No linting warnings or errors
- Modular and reusable structure

✅ **Code Review**
- Addressed all review feedback
- Fixed azure.yaml host configuration
- Fixed role assignment scope to resource level

✅ **Security Scan (CodeQL)**
- No vulnerabilities found in Actions workflows
- OIDC authentication configured correctly

✅ **Documentation**
- Comprehensive README files
- Deployment guide with troubleshooting
- Architecture diagrams (in docs)

## Next Steps for Users

1. **Initial Setup**
   ```bash
   az login
   azd auth login
   cd /path/to/repository
   ```

2. **Deploy Infrastructure**
   ```bash
   azd up
   ```
   
3. **Configure AI Models** (Optional)
   - Navigate to AI Hub in Azure Portal
   - Deploy GPT-4 and Phi models
   - Configure model endpoints

4. **Verify Deployment**
   - Access application: `https://app-zavastore-dev-westus3.azurewebsites.net`
   - Check Application Insights for telemetry
   - Review logs: `az webapp log tail`

5. **Set Up CI/CD** (Optional)
   - Configure GitHub OIDC (see DEPLOYMENT.md)
   - Add Azure secrets to GitHub repository
   - Push to main to trigger automated deployment

## Troubleshooting Resources

### Common Issues Documented
- Quota errors → Request increase or change region
- ACR pull failures → Verify managed identity and role assignment
- Container startup issues → Check logs and configuration
- AI Hub deployment failures → Verify region support and quota
- Slow deployments → Normal for first-time deployment

### Where to Find Help
1. **DEPLOYMENT.md** - Detailed troubleshooting section
2. **infra/README.md** - Infrastructure-specific issues
3. **Azure Portal** - Activity logs and resource diagnostics
4. **Application Insights** - Application errors and performance
5. **AZD Logs** - `.azure/<env-name>/logs/`

## Cost Management

### Monthly Cost Estimate (Dev Environment)
| Resource | SKU | Cost (USD/month) |
|----------|-----|------------------|
| App Service Plan | B1 | ~$13 |
| ACR | Basic | ~$5 |
| Log Analytics | Pay-as-you-go | ~$2-5 |
| App Insights | Pay-as-you-go | ~$0-5 |
| Storage Account | Standard_LRS | ~$1-2 |
| Key Vault | Standard | ~$0-1 |
| AI Hub | Basic | Pay-per-use |
| **Total** | | **~$21-31 + AI** |

### Cost Optimization
- Stop App Service when not in use
- Monitor AI model usage (most expensive)
- Use auto-shutdown for dev/test
- Delete resources with `azd down --purge`

## Cleanup

To remove all resources:
```bash
azd down --purge
```

This deletes:
- All Azure resources in the resource group
- Local AZD environment configuration

## File Structure
```
.
├── infra/
│   ├── main.bicep                    # Main orchestration
│   ├── modules/                      # Bicep modules
│   │   ├── acr.bicep
│   │   ├── appService.bicep
│   │   ├── appServicePlan.bicep
│   │   ├── appInsights.bicep
│   │   ├── logAnalytics.bicep
│   │   ├── storageAccount.bicep
│   │   ├── keyVault.bicep
│   │   ├── aiHub.bicep
│   │   └── roleAssignment.bicep
│   └── README.md                     # Infrastructure docs
├── src/                              # .NET application
├── .github/
│   └── workflows/
│       └── azure-deploy.yml          # CI/CD pipeline
├── azure.yaml                        # AZD configuration
├── Dockerfile                        # Container build
├── .dockerignore                     # Docker exclusions
├── DEPLOYMENT.md                     # Deployment guide
└── SUMMARY.md                        # This file
```

## Success Criteria Met

✅ All required Azure resources defined in Bicep
✅ App Service uses ACR with Azure RBAC (no passwords)
✅ No local Docker engine required for builds
✅ Monitoring via Application Insights enabled
✅ Microsoft Foundry available for GPT-4 and Phi
✅ Deployable in one step with `azd up`
✅ Targets westus3 region
✅ Uses dev-tier SKUs and settings
✅ Comprehensive documentation provided
✅ Security best practices implemented
✅ CI/CD pipeline included

## Support and Contributions

For issues, questions, or contributions:
1. Review documentation files (DEPLOYMENT.md, infra/README.md)
2. Check troubleshooting sections
3. Review Azure Portal activity logs
4. Check Application Insights diagnostics
5. Open GitHub issue with details

---

**Status**: ✅ Complete and Ready for Deployment  
**Version**: 1.0  
**Last Updated**: 2026-02-19  
**Region**: West US 3  
**Environment**: Development
