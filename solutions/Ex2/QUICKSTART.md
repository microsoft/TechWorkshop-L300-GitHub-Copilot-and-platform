# Quick Start Guide - ZavaStorefront Deployment

This guide will help you quickly deploy the ZavaStorefront application to Azure in minutes.

## Prerequisites Checklist

Before you begin, ensure you have:

- [ ] Active Azure subscription
- [ ] Azure CLI installed ([Download](https://learn.microsoft.com/cli/azure/install-azure-cli))
- [ ] Azure Developer CLI (azd) installed ([Download](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd))
- [ ] Basic familiarity with command line interface
- [ ] Contributor permissions on your Azure subscription

## Deployment Steps (5-10 minutes)

### Step 1: Clone the Repository

```bash
git clone https://github.com/microsoft/TechWorkshop-L300-GitHub-Copilot-and-platform.git
cd TechWorkshop-L300-GitHub-Copilot-and-platform
```

### Step 2: Login to Azure

```bash
# Login to Azure
az login

# Verify your subscription
az account show

# (Optional) Set a specific subscription if you have multiple
az account set --subscription <subscription-id>
```

### Step 3: Login to Azure Developer CLI

```bash
azd auth login
```

This will open a browser window for authentication. Use the same account as Step 2.

### Step 4: Initialize the Environment

```bash
azd init
```

When prompted:
- **Environment name**: Enter a name like `dev` or `myenv` (lowercase, no spaces)
- **Location**: Press Enter to accept the default `westus3` or choose another region

### Step 5: Deploy Everything

```bash
azd up
```

This single command will:
1. Provision all Azure resources (ACR, App Service, Application Insights, Azure Foundry)
2. Build the Docker image in the cloud (no local Docker needed)
3. Push the image to Azure Container Registry
4. Deploy the application to Azure App Service

**Expected duration**: 5-10 minutes

### Step 6: Access Your Application

After deployment completes, azd will display:
- **Web App URL**: Click this to access your deployed application
- **Resource Group**: Where all your resources are located
- **ACR Name**: Your container registry name

Example output:
```
SUCCESS: Your application was provisioned and deployed to Azure in 8 minutes 23 seconds.

You can view the resources created under the resource group rg-zavastore-dev-westus3 in Azure Portal:
https://portal.azure.com/#@/resource/subscriptions/.../resourceGroups/rg-zavastore-dev-westus3

Browse to your application: https://app-zavastore-dev-westus3.azurewebsites.net
```

## Verify Deployment

### Check Application Status

```bash
# View deployment status
azd show

# Stream application logs
azd monitor
```

### Access Azure Portal

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to your resource group: `rg-zavastore-dev-westus3`
3. Explore the deployed resources:
   - **App Service**: Click to see application metrics and logs
   - **Application Insights**: View telemetry and performance data
   - **Container Registry**: Browse container images
   - **Azure Foundry**: Manage AI model deployments

## Common Post-Deployment Tasks

### View Application Logs

```bash
# Real-time log streaming
az webapp log tail --name <webapp-name> --resource-group <resource-group-name>
```

### Update the Application

After making code changes:

```bash
# Rebuild and redeploy
azd deploy
```

### View Costs

Monitor your spending:
1. Azure Portal → Cost Management + Billing
2. Select your subscription
3. View costs by resource group

### Stop Resources (Save Money)

When not in use:

```bash
# Stop the web app (saves compute costs)
az webapp stop --name <webapp-name> --resource-group <resource-group-name>

# Restart when needed
az webapp start --name <webapp-name> --resource-group <resource-group-name>
```

## Cleanup (Delete All Resources)

When you're done:

```bash
# Delete all resources
azd down

# Confirm deletion when prompted
```

This will remove:
- Resource group and all contained resources
- No charges will accrue after deletion

## Troubleshooting

### Issue: "Subscription not found"

**Solution**: Run `az login` and `azd auth login` again with the correct account.

### Issue: "Quota exceeded for Azure Foundry"

**Solution**: 
1. Request quota increase in Azure Portal
2. Or disable Foundry deployment by editing `infra/main.parameters.dev.json`:
   ```json
   "enableFoundry": {
     "value": false
   }
   ```
3. Run `azd up` again

### Issue: "Container image not found"

**Solution**: 
1. Wait a few minutes for the initial image build
2. Check ACR build logs:
   ```bash
   az acr task logs --registry <acr-name>
   ```
3. Manually trigger a build:
   ```bash
   azd deploy
   ```

### Issue: Application shows errors

**Solution**:
1. Check application logs:
   ```bash
   az webapp log tail --name <webapp-name> --resource-group <resource-group-name>
   ```
2. Restart the application:
   ```bash
   az webapp restart --name <webapp-name> --resource-group <resource-group-name>
   ```

## Next Steps

- **Configure CI/CD**: Set up GitHub Actions for automated deployments
- **Custom Domain**: Add a custom domain to your App Service
- **Scaling**: Adjust App Service Plan SKU for more capacity
- **Security**: Configure network restrictions and private endpoints
- **Monitoring**: Set up Application Insights alerts and dashboards

## Support

For detailed documentation:
- [Infrastructure README](infra/README.md)
- [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Azure App Service Documentation](https://learn.microsoft.com/azure/app-service/)

For issues or questions, open an issue in the GitHub repository.

## Estimated Costs

Development environment (default configuration):
- Azure Container Registry (Basic): ~$5/month
- App Service Plan (B1): ~$13/month
- Application Insights: ~$2-5/month (first 5GB free)
- Azure Foundry (S0): Pay per token usage

**Total estimated cost**: $20-30/month for light development usage

**Cost-saving tips**:
- Stop App Service when not in use (saves ~$13/month)
- Delete resources completely when done: `azd down`
- Monitor costs in Azure Cost Management
