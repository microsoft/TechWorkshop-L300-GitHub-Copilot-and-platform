# ZavaStorefront Infrastructure

This folder contains the Infrastructure as Code (IaC) for deploying the ZavaStorefront web application to Azure using Bicep and Azure Developer CLI (AZD).

## 📁 Structure

```
infra/
├── main.bicep              # Main orchestration template
├── main.bicepparam         # Parameters file
├── modules/
│   ├── acr.bicep           # Azure Container Registry
│   ├── appInsights.bicep   # Application Insights
│   ├── appService.bicep    # Web App for Containers
│   ├── appServicePlan.bicep# Linux App Service Plan
│   ├── cognitiveServices.bicep # AI Services (GPT-4/Phi)
│   └── logAnalytics.bicep  # Log Analytics Workspace
└── README.md               # This file
```

## 🏗️ Resources Deployed

| Resource | Description | SKU |
|----------|-------------|-----|
| Log Analytics Workspace | Centralized logging | PerGB2018 |
| Application Insights | App monitoring | - |
| Container Registry | Docker image storage | Basic |
| App Service Plan | Linux hosting | B1 |
| Web App | Container hosting | - |
| AI Services | GPT-4 & Phi models | S0 |

## 🚀 Deployment

### Prerequisites

1. [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)
2. [Azure Developer CLI (azd)](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd)
3. [Bicep CLI](https://docs.microsoft.com/azure/azure-resource-manager/bicep/install)
4. An Azure subscription with appropriate permissions

### Quick Start

```bash
# 1. Login to Azure
az login
azd auth login

# 2. Initialize the environment (first time only)
azd init

# 3. Preview the deployment
azd provision --preview

# 4. Deploy infrastructure and application
azd up
```

### Step-by-Step Deployment

```bash
# Set environment name
azd env new dev

# Configure location (westus3 is required for AI Services)
azd env set AZURE_LOCATION westus3

# Provision infrastructure
azd provision

# Build and push container image
az acr build --registry <acr-name> --image zavastore:latest ./src

# Deploy application
azd deploy
```

## 🔧 Configuration

### Parameters

Edit `main.bicepparam` to customize:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `environmentName` | dev | Environment name |
| `location` | westus3 | Azure region |
| `baseName` | zavastore | Base name for resources |
| `appServicePlanSku` | B1 | App Service Plan SKU |
| `acrSku` | Basic | Container Registry SKU |
| `deployAiServices` | true | Deploy AI Services |
| `deployGpt4o` | true | Deploy GPT-4o model |
| `deployPhi` | true | Deploy Phi model |

### Environment Variables

After deployment, these outputs are available:

- `AZURE_CONTAINER_REGISTRY_NAME` - ACR name
- `AZURE_CONTAINER_REGISTRY_ENDPOINT` - ACR login server
- `AZURE_APP_SERVICE_NAME` - Web App name
- `SERVICE_WEB_ENDPOINT` - Application URL
- `APPLICATIONINSIGHTS_CONNECTION_STRING` - App Insights connection
- `AI_SERVICES_NAME` - AI Services account name
- `AI_SERVICES_ENDPOINT` - AI Services endpoint

## 🔐 Security

- **Managed Identity**: Web App uses system-assigned identity
- **AcrPull Role**: Web App can pull images without passwords
- **HTTPS Only**: All traffic is encrypted
- **No FTP**: Basic auth publishing is disabled
- **TLS 1.2+**: Minimum TLS version enforced

## 📊 Monitoring

Application Insights is automatically configured with:

- Request tracking
- Dependency tracking
- Exception logging
- Performance metrics

View logs in the Azure Portal or query using Log Analytics.

## 💰 Cost Estimation (Dev Environment)

| Resource | SKU | Estimated Monthly Cost |
|----------|-----|------------------------|
| App Service Plan | B1 | ~$13 |
| Container Registry | Basic | ~$5 |
| Log Analytics | Pay-as-you-go | ~$2-5 |
| Application Insights | Included | - |
| AI Services | S0 | Pay-per-use |

**Total Estimated**: ~$20-25/month + AI usage

## 🧹 Cleanup

```bash
# Remove all deployed resources
azd down

# Or manually delete the resource group
az group delete --name rg-zavastore-dev-<unique-suffix>
```

## 🐛 Troubleshooting

### Common Issues

1. **ACR Build Fails**
   - Ensure you're logged into Azure: `az login`
   - Check Dockerfile path: `./src/Dockerfile`

2. **Web App Can't Pull Image**
   - Verify AcrPull role assignment
   - Check managed identity is enabled

3. **AI Services Deployment Fails**
   - Verify westus3 region supports the models
   - Check subscription quotas

### Useful Commands

```bash
# View deployment logs
azd monitor

# Check environment values
azd env get-values

# Restart web app
az webapp restart --name <app-name> --resource-group <rg-name>

# View container logs
az webapp log tail --name <app-name> --resource-group <rg-name>
```

## 📚 References

- [Azure Verified Modules](https://azure.github.io/Azure-Verified-Modules/)
- [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [App Service for Containers](https://learn.microsoft.com/azure/app-service/configure-custom-container)
