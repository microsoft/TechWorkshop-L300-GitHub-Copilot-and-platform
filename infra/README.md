# ZavaStorefront Infrastructure

This directory contains the Infrastructure as Code (IaC) for the ZavaStorefront application using Azure Bicep templates and Azure Developer CLI (azd).

## Architecture Overview

The infrastructure provisions a complete Azure environment for hosting a containerized .NET 6 web application with the following components:

- **Azure Container Registry (ACR)**: Stores Docker container images
- **Linux App Service**: Hosts the containerized application
- **Application Insights**: Application performance monitoring and telemetry
- **Log Analytics Workspace**: Centralized logging and analytics
- **Azure OpenAI Service**: AI capabilities with GPT-4 and Phi model deployments
- **RBAC Configuration**: Managed identity-based authentication (no passwords)

### Key Features

✅ **No Local Docker Required**: Container builds happen in Azure using `az acr build`  
✅ **Managed Identity Authentication**: App Service uses RBAC to pull images from ACR  
✅ **Comprehensive Monitoring**: Application Insights integrated with Log Analytics  
✅ **AI-Ready**: Azure OpenAI Service with GPT-4 and Phi models pre-deployed  
✅ **Infrastructure as Code**: All resources defined in Bicep templates  
✅ **Automated Deployments**: GitHub Actions workflow for CI/CD  

## Prerequisites

Before deploying the infrastructure, ensure you have:

1. **Azure Subscription**: Active Azure subscription with appropriate permissions
2. **Azure CLI**: Version 2.50.0 or later ([Install](https://docs.microsoft.com/cli/azure/install-azure-cli))
3. **Azure Developer CLI (azd)**: Version 1.5.0 or later ([Install](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd))
4. **Git**: For cloning and version control
5. **.NET 6 SDK**: For local development (optional)

### Azure Permissions Required

Your Azure account needs the following permissions:
- `Contributor` role on the subscription or resource group
- `User Access Administrator` role for RBAC assignments (or use existing service principal)

## Project Structure

```
infra/
├── main.bicep                      # Main orchestration template
├── main.parameters.json            # Parameter values
├── abbreviations.json              # Resource naming abbreviations
├── modules/                        # Modular Bicep templates
│   ├── logAnalytics.bicep         # Log Analytics workspace
│   ├── appInsights.bicep          # Application Insights
│   ├── acr.bicep                  # Azure Container Registry
│   ├── appServicePlan.bicep       # App Service Plan
│   ├── webApp.bicep               # Web App (Linux container)
│   ├── openai.bicep               # Azure OpenAI Service
│   └── roleAssignments.bicep      # RBAC role assignments
└── README.md                       # This file
```

## Deployment Instructions

### Option 1: Deploy Using Azure Developer CLI (Recommended)

This is the simplest and recommended approach for development environments.

#### Step 1: Initialize Environment

```bash
# Clone the repository (if not already done)
git clone <repository-url>
cd TechWorkshop-L300-GitHub-Copilot-and-platform

# Authenticate with Azure
azd auth login

# Initialize a new environment
azd env new zava-dev

# Set the location (westus3 as specified)
azd env set AZURE_LOCATION westus3
```

#### Step 2: Provision Infrastructure

```bash
# Provision all Azure resources
azd provision
```

This command will:
- Create a resource group in westus3
- Deploy all infrastructure resources defined in Bicep templates
- Configure RBAC permissions
- Output environment variables for the deployed resources

#### Step 3: Build and Push Container

After infrastructure provisioning, build the container image:

```bash
# Get the ACR name from environment
$acrName = azd env get-value AZURE_CONTAINER_REGISTRY_NAME

# Build and push the container image to ACR
az acr build `
  --registry $acrName `
  --image zava-storefront:latest `
  --file src/Dockerfile `
  src/
```

#### Step 4: Verify Deployment

```bash
# Get the web app URL
$webAppUrl = azd env get-value AZURE_WEBAPP_URL

# Open in browser
Start-Process $webAppUrl
```

### Option 2: Manual Deployment Using Azure CLI

If you prefer manual control or want to customize parameters:

#### Step 1: Authenticate

```bash
az login
az account set --subscription <subscription-id>
```

#### Step 2: Deploy Infrastructure

```bash
# Create resource group
az group create --name rg-zava-storefront-dev --location westus3

# Deploy Bicep template
az deployment sub create `
  --location westus3 `
  --template-file infra/main.bicep `
  --parameters environmentName=zava-dev location=westus3
```

#### Step 3: Retrieve Outputs

```bash
# Get deployment outputs
$outputs = az deployment sub show `
  --name main `
  --query properties.outputs `
  --output json | ConvertFrom-Json

$acrName = $outputs.AZURE_CONTAINER_REGISTRY_NAME.value
$webAppName = $outputs.AZURE_WEBAPP_NAME.value
$resourceGroup = $outputs.AZURE_RESOURCE_GROUP.value
```

#### Step 4: Build and Deploy Container

```bash
# Build container in ACR
az acr build `
  --registry $acrName `
  --image zava-storefront:latest `
  --file src/Dockerfile `
  src/

# Web App will automatically pull the latest image
```

## GitHub Actions Setup

The repository includes a GitHub Actions workflow ([.github/workflows/azure-deploy.yml](../.github/workflows/azure-deploy.yml)) for automated deployments.

### Configuration Steps

#### Option A: Using OpenID Connect (Recommended)

1. **Create Service Principal with Federated Credentials**:

```bash
# Set variables
$appName = "zava-storefront-github"
$subscriptionId = "<your-subscription-id>"
$resourceGroup = "rg-zava-storefront-dev"

# Create service principal
az ad sp create-for-rbac --name $appName --role contributor --scopes /subscriptions/$subscriptionId/resourceGroups/$resourceGroup

# Add federated credential
az ad app federated-credential create `
  --id <app-id> `
  --parameters '{
    "name": "github-deploy",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:microsoft/TechWorkshop-L300-GitHub-Copilot-and-platform:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

2. **Configure GitHub Secrets**:

Add these as repository variables (Settings → Secrets and variables → Actions → Variables):
- `AZURE_CLIENT_ID`: Application (client) ID
- `AZURE_TENANT_ID`: Directory (tenant) ID
- `AZURE_SUBSCRIPTION_ID`: Your Azure subscription ID

#### Option B: Using Client Secret

1. **Create Service Principal**:

```bash
az ad sp create-for-rbac --name "zava-storefront-github" --sdk-auth --role contributor --scopes /subscriptions/<subscription-id>
```

2. **Configure GitHub Secret**:

Add the entire JSON output as a secret named `AZURE_CREDENTIALS`.

### Trigger Deployment

Push to the `main` branch or manually trigger the workflow:

```bash
git add .
git commit -m "Deploy infrastructure"
git push origin main
```

## Configuration

### Environment Variables

The infrastructure outputs the following environment variables (accessible via `azd env get-value <name>`):

| Variable | Description |
|----------|-------------|
| `AZURE_LOCATION` | Deployment region (westus3) |
| `AZURE_RESOURCE_GROUP` | Resource group name |
| `AZURE_CONTAINER_REGISTRY_NAME` | ACR name |
| `AZURE_CONTAINER_REGISTRY_ENDPOINT` | ACR login server |
| `AZURE_WEBAPP_NAME` | Web App name |
| `AZURE_WEBAPP_URL` | Web App public URL |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | Application Insights connection string |
| `AZURE_OPENAI_ENDPOINT` | Azure OpenAI endpoint |
| `AZURE_OPENAI_GPT4_DEPLOYMENT_NAME` | GPT-4 deployment name |
| `AZURE_OPENAI_PHI_DEPLOYMENT_NAME` | Phi deployment name |

### Resource Naming Convention

Resources follow Azure naming best practices with abbreviations:

- Resource Group: `rg-<environment-name>`
- Container Registry: `cr<unique-token>`
- App Service Plan: `plan-<unique-token>`
- Web App: `app-<unique-token>`
- Application Insights: `appi-<unique-token>`
- Log Analytics: `log-<unique-token>`
- Azure OpenAI: `oai-<unique-token>`

## Cost Considerations

All resources are configured for **development environments** with cost-effective SKUs:

| Resource | SKU | Estimated Monthly Cost* |
|----------|-----|------------------------|
| Container Registry | Basic | ~$5 |
| App Service Plan | B1 (Basic) | ~$13 |
| Application Insights | Pay-as-you-go | ~$0-5 (dev usage) |
| Log Analytics | Pay-as-you-go | ~$0-5 (dev usage) |
| Azure OpenAI | S0 Standard | Pay-per-token (~$10-50 dev) |

**Total Estimated**: ~$33-78/month for light development usage

*Prices are estimates and subject to change. Actual costs depend on usage.

### Cost Optimization Tips

- Delete resources when not in use: `azd down --purge --force`
- Use Free tier App Service for non-production: Change SKU to `F1`
- Set Log Analytics daily cap to control costs
- Monitor Azure OpenAI token usage

## Troubleshooting

### Common Issues

#### Issue: ACR Authentication Fails

**Symptom**: Web App cannot pull container images  
**Solution**: Verify RBAC assignment

```bash
# Check role assignment
az role assignment list --assignee <web-app-principal-id> --scope /subscriptions/<subscription-id>/resourceGroups/<rg-name>/providers/Microsoft.ContainerRegistry/registries/<acr-name>

# Manually assign if missing
az role assignment create --assignee <web-app-principal-id> --role AcrPull --scope <acr-resource-id>
```

#### Issue: Application Insights Not Showing Data

**Symptom**: No telemetry in Application Insights  
**Solution**: Verify connection string is set

```bash
# Check app settings
az webapp config appsettings list --name <webapp-name> --resource-group <rg-name>

# Update if needed
az webapp config appsettings set --name <webapp-name> --resource-group <rg-name> --settings APPLICATIONINSIGHTS_CONNECTION_STRING="<connection-string>"
```

#### Issue: Azure OpenAI Model Deployment Fails

**Symptom**: Deployment shows GPT-4 or Phi model unavailable  
**Solution**: Check region availability and quota

```bash
# List available models in region
az cognitiveservices account list-models --name <openai-name> --resource-group <rg-name>

# Adjust deployment in infra/modules/openai.bicep if needed
```

#### Issue: Container Build Fails

**Symptom**: `az acr build` returns errors  
**Solution**: Check Dockerfile and build context

```bash
# Test locally first (requires Docker)
docker build -t zava-storefront:test -f src/Dockerfile src/

# Check ACR task logs
az acr task logs --registry <acr-name>
```

### Health Check

Verify all components are working:

```bash
# 1. Check infrastructure status
azd show

# 2. Verify web app is running
curl https://<webapp-url>/health

# 3. Check Application Insights
az monitor app-insights component show --app <appinsights-name> --resource-group <rg-name>

# 4. Test Azure OpenAI (requires code integration)
# See application code for usage examples
```

## Security Best Practices

✅ **Managed Identities**: No passwords or keys stored for ACR/OpenAI access  
✅ **HTTPS Only**: All web traffic encrypted  
✅ **Minimal Permissions**: Service principal uses least privilege  
✅ **Network Security**: Public access enabled for dev (restrict for production)  
✅ **Secret Management**: Sensitive values stored in Key Vault (future enhancement)  

### Recommended for Production

- Enable Private Endpoints for ACR and OpenAI
- Add Web Application Firewall (WAF)
- Implement Azure Key Vault for secrets
- Enable Azure DDoS Protection
- Configure custom domains with SSL certificates
- Implement Azure Front Door for global distribution

## Cleanup

To completely remove all resources:

```bash
# Using azd (recommended)
azd down --purge --force

# Or manually
az group delete --name <resource-group-name> --yes --no-wait
```

## Additional Resources

- [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Bicep Language Reference](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure App Service Documentation](https://learn.microsoft.com/azure/app-service/)
- [Azure Container Registry Documentation](https://learn.microsoft.com/azure/container-registry/)
- [Azure OpenAI Service Documentation](https://learn.microsoft.com/azure/ai-services/openai/)
- [Application Insights Documentation](https://learn.microsoft.com/azure/azure-monitor/app/app-insights-overview)

## Support

For issues or questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review Azure Portal diagnostics
3. Check Application Insights Live Metrics
4. File an issue in the repository

---

**Last Updated**: February 2026  
**Infrastructure Version**: 1.0.0  
**Maintained By**: Microsoft Workshop Team
