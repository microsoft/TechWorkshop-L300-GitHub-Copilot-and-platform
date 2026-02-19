# Azure Infrastructure Deployment Guide

This guide walks you through deploying the complete ZavaStorefront infrastructure to Azure using Azure Developer CLI (AZD) and Bicep templates.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Detailed Deployment Steps](#detailed-deployment-steps)
4. [Post-Deployment Configuration](#post-deployment-configuration)
5. [Building and Deploying the Application](#building-and-deploying-the-application)
6. [Verification](#verification)
7. [Troubleshooting](#troubleshooting)
8. [Cleanup](#cleanup)

## Prerequisites

### Required Tools
1. **Azure CLI** (version 2.50.0 or later)
   ```bash
   # Install on macOS
   brew install azure-cli
   
   # Install on Windows
   winget install Microsoft.AzureCLI
   
   # Install on Linux
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   
   # Verify installation
   az --version
   ```

2. **Azure Developer CLI (AZD)** (version 1.5.0 or later)
   ```bash
   # Install on macOS/Linux
   curl -fsSL https://aka.ms/install-azd.sh | bash
   
   # Install on Windows (PowerShell)
   powershell -ex AllSigned -c "Invoke-RestMethod 'https://aka.ms/install-azd.ps1' | Invoke-Expression"
   
   # Verify installation
   azd version
   ```

3. **Git** (for cloning the repository)
   ```bash
   git --version
   ```

### Azure Requirements
- Active Azure subscription
- Permissions to create:
  - Resource groups
  - Container registries
  - App Services
  - Log Analytics workspaces
  - Application Insights
  - AI Hub (Machine Learning workspaces)
  - Storage accounts
  - Key Vaults
- Quota availability for AI Hub in West US 3 region

### Optional Tools
- **Docker** (NOT required - builds happen in the cloud via ACR)
- **Visual Studio Code** (recommended for local development)

## Quick Start

For experienced users, here's the fastest path to deployment:

```bash
# 1. Login to Azure
az login
azd auth login

# 2. Clone and navigate to the repository
cd /path/to/TechWorkshop-L300-GitHub-Copilot-and-platform

# 3. Initialize AZD
azd init

# 4. Deploy everything (infrastructure + application)
azd up
```

When prompted:
- **Environment name**: `dev` (or your preferred name)
- **Subscription**: Select your Azure subscription
- **Location**: `westus3` (required for AI Hub with GPT-4/Phi models)

The deployment takes approximately 10-15 minutes.

## Detailed Deployment Steps

### Step 1: Authenticate with Azure

```bash
# Login to Azure CLI
az login

# Set your subscription (if you have multiple)
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Verify the active subscription
az account show

# Login to Azure Developer CLI
azd auth login
```

### Step 2: Clone the Repository

```bash
# Clone the repository
git clone https://github.com/ZavaLabs123/TechWorkshop-L300-GitHub-Copilot-and-platform.git

# Navigate to the repository
cd TechWorkshop-L300-GitHub-Copilot-and-platform
```

### Step 3: Initialize Azure Developer CLI

```bash
# Initialize AZD in the repository
azd init
```

You'll be prompted with:

1. **Scan for services?** → Select "Yes" (or press Enter)
2. **Detected .NET application in ./src** → Confirm
3. **Service name** → Accept default "web" (or customize)
4. **Port number** → Accept default 80

This creates or updates the `azure.yaml` file with your service configuration.

### Step 4: Preview Infrastructure (Optional)

Before deploying, you can preview what will be created:

```bash
azd provision --preview
```

You'll be prompted for:

1. **Environment name** (e.g., `dev`, `staging`, `prod`)
   - This name is used to generate resource names
   - Use lowercase, alphanumeric characters only
   - Maximum 10 characters

2. **Azure subscription**
   - Select from your available subscriptions

3. **Azure location**
   - Select `West US 3` (recommended for AI Hub)
   - This region supports GPT-4 and Phi models

The preview will show:
- Resource group name
- All resources to be created
- Estimated deployment time

Review the output carefully before proceeding.

### Step 5: Deploy Infrastructure and Application

Deploy everything with a single command:

```bash
azd up
```

This command:
1. **Provisions infrastructure** (via Bicep templates)
   - Creates resource group
   - Deploys ACR, App Service, AI Hub, etc.
   - Configures RBAC permissions
   
2. **Packages the application**
   - Builds the .NET application
   
3. **Builds Docker image** (in ACR - no local Docker needed)
   - Uses `az acr build` to build in the cloud
   
4. **Deploys to App Service**
   - Updates App Service with new container image

**Expected output:**
```
Provisioning Azure resources (azd provision)
  (✓) Done: Resource group: rg-zavastore-dev-westus3
  (✓) Done: Log Analytics workspace
  (✓) Done: Application Insights
  (✓) Done: Azure Container Registry
  (✓) Done: Storage Account
  (✓) Done: Key Vault
  (✓) Done: App Service Plan
  (✓) Done: App Service
  (✓) Done: AI Hub
  (✓) Done: Role assignment (AcrPull)

Packaging services (azd package)
  (✓) Done: Service web

Building and pushing images (azd deploy)
  (✓) Done: Building image in ACR
  (✓) Done: Deploying to App Service

SUCCESS: Your application was provisioned and deployed to Azure in 14 minutes 32 seconds.

You can view the resources created under the resource group rg-zavastore-dev-westus3 in Azure Portal:
https://portal.azure.com/#@/resource/subscriptions/.../resourceGroups/rg-zavastore-dev-westus3

App Service URL: https://app-zavastore-dev-westus3.azurewebsites.net
```

### Alternative: Deploy in Stages

If you prefer more control, deploy infrastructure and application separately:

```bash
# 1. Provision infrastructure only
azd provision

# 2. Package application
azd package

# 3. Deploy application
azd deploy
```

## Post-Deployment Configuration

### 1. Verify Resource Creation

Check that all resources were created successfully:

```bash
# List all resources in the resource group
az resource list --resource-group rg-zavastore-dev-westus3 --output table
```

Expected resources:
- Container Registry (ACR)
- App Service Plan
- App Service (Web App)
- Log Analytics Workspace
- Application Insights
- Storage Account
- Key Vault
- AI Hub (Machine Learning Workspace)

### 2. Configure AI Hub Models

After deployment, configure GPT-4 and Phi models in AI Hub:

1. Navigate to Azure Portal: https://portal.azure.com
2. Go to your resource group (e.g., `rg-zavastore-dev-westus3`)
3. Open the AI Hub resource (e.g., `aih-zavastore-dev-westus3`)
4. Go to **Model catalog** → **Deploy models**
5. Deploy the required models:
   - **GPT-4** (or GPT-4-32k)
   - **Phi-3** (or latest Phi variant)

**Important**: Model deployment may take 5-10 minutes and requires available quota.

### 3. Configure App Service Settings (Optional)

Add any additional environment variables needed by your application:

```bash
az webapp config appsettings set \
  --name app-zavastore-dev-westus3 \
  --resource-group rg-zavastore-dev-westus3 \
  --settings KEY1=VALUE1 KEY2=VALUE2
```

### 4. Enable Diagnostic Logging

Enable detailed logging for troubleshooting:

```bash
az webapp log config \
  --name app-zavastore-dev-westus3 \
  --resource-group rg-zavastore-dev-westus3 \
  --docker-container-logging filesystem \
  --level verbose
```

## Building and Deploying the Application

### Method 1: Using AZD (Recommended)

```bash
# Deploy application (builds image in ACR automatically)
azd deploy
```

### Method 2: Using Azure CLI Directly

```bash
# Get ACR name from your deployment
ACR_NAME=$(az acr list --resource-group rg-zavastore-dev-westus3 --query "[0].name" -o tsv)

# Build image in ACR (cloud build - no local Docker needed)
az acr build \
  --registry $ACR_NAME \
  --image zavastore:latest \
  --file ./Dockerfile \
  ./src

# Get the full image name
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer -o tsv)

# Update App Service to use the new image
az webapp config container set \
  --name app-zavastore-dev-westus3 \
  --resource-group rg-zavastore-dev-westus3 \
  --docker-custom-image-name $ACR_LOGIN_SERVER/zavastore:latest
```

### Method 3: Using GitHub Actions (CI/CD)

The repository includes a GitHub Actions workflow (`.github/workflows/azure-deploy.yml`) for automated deployments.

**Setup:**

1. Configure Azure credentials for GitHub Actions using OIDC:

```bash
# Create an Azure AD application
az ad app create --display-name "ZavaStorefront-GitHub-Actions"

# Create a service principal
az ad sp create --id <APP_ID>

# Create federated credentials for GitHub
az ad app federated-credential create \
  --id <APP_ID> \
  --parameters '{
    "name": "ZavaStorefront-GitHub",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:ZavaLabs123/TechWorkshop-L300-GitHub-Copilot-and-platform:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Assign Contributor role to the service principal
az role assignment create \
  --assignee <APP_ID> \
  --role Contributor \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/rg-zavastore-dev-westus3
```

2. Add these secrets to your GitHub repository:
   - `AZURE_CLIENT_ID`: Application (client) ID
   - `AZURE_TENANT_ID`: Directory (tenant) ID
   - `AZURE_SUBSCRIPTION_ID`: Subscription ID

3. Push to main branch → GitHub Actions automatically builds and deploys

## Verification

### 1. Verify App Service is Running

```bash
# Check App Service status
az webapp show \
  --name app-zavastore-dev-westus3 \
  --resource-group rg-zavastore-dev-westus3 \
  --query "state" -o tsv
```

Expected output: `Running`

### 2. Access the Application

Open your browser and navigate to:
```
https://app-zavastore-dev-westus3.azurewebsites.net
```

You should see the ZavaStorefront homepage with product listings.

### 3. Check Application Logs

```bash
# Stream live logs
az webapp log tail \
  --name app-zavastore-dev-westus3 \
  --resource-group rg-zavastore-dev-westus3
```

Or view logs in Azure Portal:
1. Navigate to App Service
2. Click **Monitoring** → **Log stream**

### 4. Verify Application Insights

1. Navigate to Application Insights in Azure Portal
2. Check **Live Metrics** to see real-time telemetry
3. View **Application Map** to see dependencies
4. Check **Failures** and **Performance** tabs

### 5. Verify ACR Integration

```bash
# Verify App Service can pull from ACR
az webapp config show \
  --name app-zavastore-dev-westus3 \
  --resource-group rg-zavastore-dev-westus3 \
  --query "siteConfig.linuxFxVersion"
```

Expected output should show your ACR image path.

## Troubleshooting

### Issue: AZD Provision Fails with Quota Error

**Error**: `QuotaExceeded: Operation could not be completed as it results in exceeding quota limits`

**Solution**:
1. Check your quota:
   ```bash
   az vm list-usage --location westus3 -o table
   ```
2. Request quota increase in Azure Portal
3. Or try a different region (may affect AI Hub model availability)

### Issue: AI Hub Deployment Fails

**Error**: `The specified region does not support this resource type`

**Solution**:
- Ensure you're deploying to `westus3`
- Check [AI Foundry region support](https://learn.microsoft.com/azure/ai-foundry/reference/region-support)
- Verify your subscription has access to AI Hub

### Issue: App Service Shows "Container didn't respond to HTTP pings"

**Error**: Container fails to start or times out

**Solution**:
1. Check container logs:
   ```bash
   az webapp log tail --name app-zavastore-dev-westus3 --resource-group rg-zavastore-dev-westus3
   ```

2. Verify the image exists in ACR:
   ```bash
   az acr repository show-tags --name <acr-name> --repository zavastore
   ```

3. Check App Service configuration:
   ```bash
   az webapp config show --name app-zavastore-dev-westus3 --resource-group rg-zavastore-dev-westus3
   ```

4. Restart the App Service:
   ```bash
   az webapp restart --name app-zavastore-dev-westus3 --resource-group rg-zavastore-dev-westus3
   ```

### Issue: ACR Pull Authorization Failed

**Error**: `Failed to pull image: unauthorized: authentication required`

**Solution**:
1. Verify managed identity is assigned:
   ```bash
   az webapp identity show --name app-zavastore-dev-westus3 --resource-group rg-zavastore-dev-westus3
   ```

2. Verify AcrPull role assignment:
   ```bash
   az role assignment list --scope /subscriptions/<subscription-id>/resourceGroups/rg-zavastore-dev-westus3/providers/Microsoft.ContainerRegistry/registries/<acr-name>
   ```

3. Re-deploy the role assignment:
   ```bash
   azd provision
   ```

### Issue: Application Insights Not Showing Data

**Solution**:
1. Verify connection string is configured:
   ```bash
   az webapp config appsettings list --name app-zavastore-dev-westus3 --resource-group rg-zavastore-dev-westus3 --query "[?name=='APPLICATIONINSIGHTS_CONNECTION_STRING']"
   ```

2. Wait 5-10 minutes for data to appear (initial delay is normal)

3. Check Application Insights ingestion status in Azure Portal

### Issue: AZD Commands Are Slow

**Solution**:
- AZD operations can take 10-20 minutes depending on resources
- Use `azd provision --preview` first to validate without deploying
- Monitor progress in Azure Portal during deployment

## Cleanup

### Option 1: Delete All Resources (Recommended)

Remove all Azure resources and local AZD environment:

```bash
azd down --purge
```

This command:
- Deletes the entire resource group
- Removes all Azure resources
- Cleans up local AZD environment configuration

**Warning**: This is irreversible. Ensure you've backed up any data.

### Option 2: Delete Resource Group Only

Keep AZD environment configuration, delete Azure resources:

```bash
az group delete --name rg-zavastore-dev-westus3 --yes --no-wait
```

### Option 3: Delete Specific Resources

Delete individual resources while keeping others:

```bash
# Delete App Service
az webapp delete --name app-zavastore-dev-westus3 --resource-group rg-zavastore-dev-westus3

# Delete ACR
az acr delete --name <acr-name> --resource-group rg-zavastore-dev-westus3 --yes

# Delete AI Hub
az ml workspace delete --name aih-zavastore-dev-westus3 --resource-group rg-zavastore-dev-westus3 --yes
```

## Cost Management

### Monitor Costs

```bash
# View cost analysis
az consumption usage list --start-date 2024-01-01 --end-date 2024-01-31
```

Or use Azure Portal:
1. Navigate to **Cost Management + Billing**
2. Select your subscription
3. View **Cost analysis**

### Estimated Monthly Costs (Development Environment)

| Resource | SKU | Approximate Cost (USD/month) |
|----------|-----|------------------------------|
| App Service Plan | B1 | $13 |
| ACR | Basic | $5 |
| Log Analytics | Pay-as-you-go | $2-5 |
| Application Insights | Pay-as-you-go | $0-5 |
| Storage Account | Standard_LRS | $1-2 |
| Key Vault | Standard | $0-1 |
| AI Hub | Basic (pay-per-use) | Variable |
| **Total** | | **$21-31 + AI usage** |

**Note**: AI Hub model usage (GPT-4, Phi) is billed separately based on token consumption.

### Cost Optimization Tips

1. **Stop App Service when not in use**:
   ```bash
   az webapp stop --name app-zavastore-dev-westus3 --resource-group rg-zavastore-dev-westus3
   ```

2. **Use auto-shutdown schedules** for development environments

3. **Monitor AI model usage** carefully (most expensive component)

4. **Delete resources when not needed**:
   ```bash
   azd down --purge
   ```

## Additional Resources

- [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [App Service Documentation](https://learn.microsoft.com/azure/app-service/)
- [Azure Container Registry Documentation](https://learn.microsoft.com/azure/container-registry/)
- [Application Insights Documentation](https://learn.microsoft.com/azure/azure-monitor/app/app-insights-overview)
- [AI Hub (Microsoft Foundry) Documentation](https://learn.microsoft.com/azure/ai-foundry/)

## Support

For issues or questions:
1. Check this troubleshooting guide
2. Review Azure Portal activity logs
3. Check Application Insights for application errors
4. Review AZD logs: `.azure/<environment-name>/logs/`
5. Open an issue in the GitHub repository

---

**Last Updated**: 2026-02-19  
**Version**: 1.0  
**Maintained By**: ZavaLabs
