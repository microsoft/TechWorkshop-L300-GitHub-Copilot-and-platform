# ZavaStorefront Azure Infrastructure

This directory contains Bicep templates and configuration for deploying the ZavaStorefront application to Azure using Azure Developer CLI (AZD).

## Architecture Overview

The infrastructure deploys the following Azure resources in the **westus3** region:

- **Resource Group**: Single resource group containing all resources
- **Azure Container Registry (ACR)**: Stores Docker container images with managed identity authentication
- **App Service Plan (Linux)**: Hosts the containerized web application
- **Web App**: ASP.NET Core 6.0 application running in a Linux container
- **Application Insights**: Application performance monitoring and telemetry
- **Log Analytics Workspace**: Centralized logging and diagnostics
- **Microsoft Foundry**: AI workspace with GPT-4 and Phi models
- **Storage Account**: Required for Foundry workspace
- **Key Vault**: Secure secrets management for Foundry

## Prerequisites

Before deploying, ensure you have the following installed:

1. **Azure CLI** (v2.50.0 or later)
   ```bash
   az --version
   ```
   Install: https://docs.microsoft.com/cli/azure/install-azure-cli

2. **Azure Developer CLI (azd)** (v1.0.0 or later)
   ```bash
   azd version
   ```
   Install: https://aka.ms/install-azd

3. **Bicep CLI** (comes with Azure CLI)
   ```bash
   az bicep version
   ```

4. **.NET 6.0 SDK** (for application development)
   ```bash
   export PATH="$HOME/.dotnet:$PATH" && dotnet --version
   ```

## Directory Structure

```
infra/
├── main.bicep                  # Main orchestration template
├── main.parameters.json        # Parameter values for deployment
├── modules/
│   ├── acr.bicep              # Azure Container Registry module
│   ├── app-service.bicep      # App Service Plan and Web App module
│   ├── app-insights.bicep     # Application Insights and Log Analytics module
│   ├── foundry.bicep          # Microsoft Foundry workspace module
│   └── role-assignments.bicep # RBAC role assignments module
└── README.md                   # This file
```

## Deployment Instructions

### 1. Authenticate to Azure

```bash
# Login to Azure
az login

# Set your subscription (if you have multiple)
az account set --subscription <subscription-id>

# Authenticate AZD
azd auth login
```

### 2. Initialize AZD Environment

```bash
# Initialize a new environment (first time only)
azd init

# Or use an existing environment name
azd env new dev
```

### 3. Set Environment Variables (Optional)

Override default parameters by setting environment variables:

```bash
azd env set AZURE_LOCATION westus3
azd env set AZURE_ENV_NAME dev
```

### 4. Preview the Deployment

Validate Bicep templates and preview changes without deploying:

```bash
# Validate Bicep syntax
az bicep build --file infra/main.bicep

# Preview what will be deployed
azd provision --preview
```

### 5. Deploy Infrastructure

Deploy all Azure resources with a single command:

```bash
azd up
```

This command will:
- Provision all Azure resources defined in Bicep templates
- Create the resource group in westus3
- Deploy ACR, App Service, Application Insights, and Foundry
- Assign managed identity permissions

### 6. Build and Deploy Application Container

After infrastructure is provisioned, build and deploy the container image:

```bash
# Get ACR name from deployment outputs
ACR_NAME=$(azd env get-values --output json | jq -r '.ACR_NAME')

# Build container image in Azure (no local Docker required)
cd src
az acr build --registry $ACR_NAME --image zavastore:latest .

# Restart App Service to pull the new image
WEB_APP_NAME=$(azd env get-values --output json | jq -r '.WEB_APP_NAME')
RESOURCE_GROUP=$(azd env get-values --output json | jq -r '.AZURE_RESOURCE_GROUP')

az webapp restart --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP
```

### 7. Access the Application

```bash
# Get the Web App URL
azd env get-values | grep WEB_APP_URL

# Or open directly in browser
az webapp browse --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP
```

## Configuration Parameters

You can customize the deployment by modifying `main.parameters.json` or passing parameters:

| Parameter | Description | Default | Allowed Values |
|-----------|-------------|---------|----------------|
| `environmentName` | Environment name (dev, staging, prod) | `dev` | 2-10 characters |
| `location` | Azure region | `westus3` | Any Azure region |
| `appServiceSku` | App Service Plan SKU | `B1` | B1, B2, B3, S1, S2, S3 |
| `acrSku` | Container Registry SKU | `Basic` | Basic, Standard, Premium |
| `containerImage` | Docker image name with tag | `zavastore:latest` | Any valid image name |

## Managed Identity and RBAC

The infrastructure uses Azure Managed Identity for secure authentication:

- **App Service** has a system-assigned managed identity
- The identity is granted **AcrPull** role on the Container Registry
- No passwords or keys are used for ACR authentication
- **Microsoft Foundry** has a system-assigned managed identity for AI model access

## Monitoring and Diagnostics

### Application Insights

Access application telemetry and performance metrics:

```bash
# Get Application Insights connection string
azd env get-values | grep APPLICATIONINSIGHTS_CONNECTION_STRING
```

Navigate to Application Insights in the Azure Portal to view:
- Request rates and response times
- Failed requests and exceptions
- Dependency tracking
- Live metrics stream

### Log Analytics

Query logs using Kusto Query Language (KQL):

```bash
# Get Log Analytics Workspace ID
az monitor log-analytics workspace show \
  --resource-group $RESOURCE_GROUP \
  --workspace-name log-zavastore-dev-westus3 \
  --query id -o tsv
```

Example queries:
- Application logs: `AppTraces | where TimeGenerated > ago(1h)`
- Exceptions: `AppExceptions | where TimeGenerated > ago(24h)`
- Performance: `AppRequests | summarize avg(DurationMs) by bin(TimeGenerated, 5m)`

## GitHub Actions CI/CD (Coming Soon)

The project will include GitHub Actions workflows for automated builds and deployments:

1. **Build & Test**: Compile application, run tests
2. **Container Build**: Build Docker image and push to ACR
3. **Deploy**: Deploy to App Service from ACR
4. **Security Scanning**: Dependabot, secret scanning, code scanning

## Troubleshooting

### Issue: App Service can't pull image from ACR

**Solution**: Verify managed identity role assignment:

```bash
# Check if AcrPull role is assigned
az role assignment list \
  --assignee $(az webapp identity show --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP --query principalId -o tsv) \
  --scope $(az acr show --name $ACR_NAME --query id -o tsv)
```

### Issue: Bicep deployment fails

**Solution**: Check Bicep syntax and validate template:

```bash
az bicep build --file infra/main.bicep
az deployment sub validate --location westus3 --template-file infra/main.bicep
```

### Issue: Container build fails

**Solution**: Ensure you're in the correct directory with Dockerfile:

```bash
cd src
az acr build --registry $ACR_NAME --image zavastore:latest . --verbose
```

### Issue: Application Insights not receiving telemetry

**Solution**: Verify connection string is set in App Service:

```bash
az webapp config appsettings list \
  --name $WEB_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  | grep -i applicationinsights
```

## Cost Estimation

Estimated monthly costs for dev environment (westus3):

| Service | SKU | Est. Monthly Cost (USD) |
|---------|-----|------------------------|
| App Service Plan | B1 (Linux) | ~$13.00 |
| Azure Container Registry | Basic | ~$5.00 |
| Application Insights | Pay-as-you-go | ~$2-10 |
| Log Analytics | Pay-as-you-go | ~$2-5 |
| Microsoft Foundry | Pay-as-you-go | Variable (token-based) |
| Storage Account | Standard LRS | ~$0.50 |
| Key Vault | Standard | ~$0.30 |
| **Total** | | **~$23-34/month** + AI usage |

*Note: Costs are estimates and may vary based on usage patterns.*

## Resource Cleanup

To delete all deployed resources:

```bash
# Delete the entire environment
azd down

# Or manually delete the resource group
az group delete --name rg-zavastore-dev-westus3 --yes --no-wait
```

## Security Best Practices

✅ **Implemented:**
- Managed identities for service-to-service authentication
- RBAC role assignments (least privilege)
- HTTPS enforcement on App Service
- TLS 1.2 minimum version
- Admin user disabled on ACR
- Soft delete enabled on Key Vault

🔄 **Recommended for Production:**
- Enable VNet integration for App Service
- Use Private Endpoints for ACR and Storage
- Implement Azure Front Door or Application Gateway
- Enable diagnostic settings on all resources
- Configure backup and disaster recovery
- Implement Azure Policy for compliance
- Use Azure Key Vault references for app settings

## Additional Resources

- [Azure Developer CLI Documentation](https://aka.ms/azure-dev)
- [Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)
- [App Service Linux Containers](https://docs.microsoft.com/azure/app-service/configure-custom-container)
- [Azure Container Registry](https://docs.microsoft.com/azure/container-registry/)
- [Application Insights](https://docs.microsoft.com/azure/azure-monitor/app/app-insights-overview)
- [Microsoft Foundry](https://aka.ms/azureai/foundry)

## Support

For issues or questions:
1. Check the [troubleshooting section](#troubleshooting) above
2. Review Azure Portal diagnostic logs
3. Check Application Insights for application errors
4. Consult workshop documentation in `/docs` directory
5. Open a GitHub issue with full error details

---

**Last Updated**: February 2026  
**Maintained By**: ZavaStorefront Team
