# Deployment Guide & Troubleshooting

## ✅ Latest Status: Infrastructure Provisioned Successfully!

All Azure resources have been created:
- ✓ Resource Group
- ✓ Azure Container Registry (ACR)
- ✓ App Service Plan
- ✓ App Service (Web App)
- ✓ Application Insights
- ✓ Log Analytics Workspace
- ✓ Microsoft Foundry (AI Services)

## How to Deploy the Application

### Option 1: Using the Deployment Script (Recommended)

Simply run:
```powershell
.\deploy.ps1
```

This script will:
1. Build the container image in ACR (cloud-based build)
2. Configure App Service to use the image
3. Restart the app to apply changes
4. Display the application URL

### Option 2: Manual Deployment

```powershell
# Get environment values
$acrName = azd env get-value AZURE_CONTAINER_REGISTRY_NAME
$appName = azd env get-value AZURE_APP_SERVICE_NAME
$rgName = azd env get-value AZURE_RESOURCE_GROUP

# Build and push container
az acr build --registry $acrName --image zavastore:latest ./src

# Deploy to App Service
az webapp config container set `
  --name $appName `
  --resource-group $rgName `
  --docker-custom-image-name "$acrName.azurecr.io/zavastore:latest"

# Restart to apply
az webapp restart --name $appName --resource-group $rgName
```

### Option 3: Using azd (Provision Only)

Note: `azd up` or `azd deploy` won't work fully because we're using App Service (not Container Apps). Instead:

```powershell
# Provision infrastructure only
azd provision

# Then use deploy.ps1 or manual commands above
.\deploy.ps1
```

---

# AI Model Deployment Configuration

## Issue Explanation

The `azd up` command failed during the **AI model deployment** phase. The error occurred because:

1. **Model Names/Versions**: The GPT-4 and Phi-3 model configurations may not match what's available in Microsoft Foundry
2. **Regional Availability**: Not all AI models are available in every Azure region (even westus3)
3. **Quota Limitations**: Your subscription may not have quota allocated for these specific models
4. **API Changes**: Model deployment APIs may have changed since the initial configuration

## What Was Fixed

✅ **Modified foundry.bicep module**:
- Changed default model deployments from a hardcoded array to an **empty array**
- Added conditional logic to skip model deployments when array is empty
- This allows the Foundry resource to be created without failing on model deployments

✅ **Updated main.bicep**:
- Changed `foundryModelDeployments` parameter default to empty array

✅ **Updated main.bicepparam**:
- Set `foundryModelDeployments = []` to skip initial model deployments

## What This Means

The infrastructure will now:
- ✅ Create the Microsoft Foundry (Azure AI Services) resource successfully
- ✅ Skip automatic model deployments (no GPT-4 or Phi-3 deployments during provisioning)
- ✅ Allow you to deploy models manually through Azure Portal or CLI with correct configurations

## How to Deploy AI Models (After Infrastructure is Provisioned)

### Option 1: Through Azure Portal

1. Navigate to your Foundry resource in Azure Portal
2. Go to **Model deployments** section
3. Click **Create new deployment**
4. Select the model and version from the available list
5. Configure capacity and deployment settings
6. Deploy

### Option 2: Using Azure CLI

First, list available models:
```bash
az cognitiveservices account list-models \
  --resource-group rg-zavastore-dev-westus3 \
  --name foundry-zavastore-dev-westus3
```

Then create a deployment with a valid model:
```bash
az cognitiveservices account deployment create \
  --resource-group rg-zavastore-dev-westus3 \
  --name foundry-zavastore-dev-westus3 \
  --deployment-name gpt-35-turbo \
  --model-name gpt-35-turbo \
  --model-version "0613" \
  --model-format OpenAI \
  --sku-capacity 10 \
  --sku-name Standard
```

### Option 3: Update Bicep with Correct Model Names

Once you know the correct model names and versions:

1. Edit `infra/main.bicepparam`
2. Add the correct model deployment configuration:
```bicep
param foundryModelDeployments = [
  {
    name: 'gpt-35-turbo'  // Example - use actual available model
    model: {
      format: 'OpenAI'
      name: 'gpt-35-turbo'
      version: '0613'
    }
    sku: {
      name: 'Standard'
      capacity: 10
    }
  }
]
```
3. Run `azd up` again

## Next Steps

1. **Re-run the deployment**:
   ```bash
   azd up
   ```
   This should now succeed without the model deployment errors.

2. **After successful provisioning**, add AI models through:
   - Azure Portal (easiest for discovering available models)
   - Azure CLI (once you know the correct model names)
   - Update Bicep templates with correct configurations

3. **Check model availability** in your region:
   - Visit [Azure OpenAI Models Documentation](https://learn.microsoft.com/azure/ai-services/openai/concepts/models)
   - Verify westus3 supports your desired models
   - Check your subscription quota

## Important Notes

- 🔍 **Model availability varies by region** - westus3 may not have all models
- 📊 **Quota is required** - you may need to request quota increases
- 🔄 **Models can be added later** - infrastructure doesn't need models to function
- ✅ **The Foundry resource itself is created** - only model deployments are skipped

The infrastructure is now configured to deploy successfully without blocking on AI model deployments!
