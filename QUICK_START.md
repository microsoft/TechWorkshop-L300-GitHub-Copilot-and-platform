# ZavaStorefront - Quick Start Guide

## ✅ Current Status

**Infrastructure**: ✓ Provisioned  
**Application**: Ready to deploy

## 🚀 Deploy the Application

Run this single command:

```powershell
.\deploy.ps1
```

That's it! The script will:
1. Build the container image in Azure
2. Deploy to App Service
3. Show you the application URL

## 📋 Complete Workflow

### First Time Setup

1. **Provision infrastructure** (already done!):
   ```powershell
   azd provision
   ```

2. **Deploy application**:
   ```powershell
   .\deploy.ps1
   ```

### Subsequent Updates

After making code changes:

```powershell
.\deploy.ps1
```

This rebuilds and redeploys automatically.

## 🔍 View Your Application

After deployment completes, visit:
```
https://<your-app-name>.azurewebsites.net
```

The URL will be displayed at the end of deployment.

## 📊 Monitor & Troubleshoot

### View Live Logs
```powershell
$appName = azd env get-value AZURE_APP_SERVICE_NAME
$rgName = azd env get-value AZURE_RESOURCE_GROUP

az webapp log tail --name $appName --resource-group $rgName
```

### View Application Insights
Go to Azure Portal → Application Insights → appi-zavastore-dev-westus3

### Check Container Status
```powershell
az webapp show --name $appName --resource-group $rgName --query state
```

## 🛠️ Common Commands

```powershell
# Get all environment values
azd env get-values

# View resource group in portal
$rgName = azd env get-value AZURE_RESOURCE_GROUP
start "https://portal.azure.com/#@/resource/subscriptions/<sub-id>/resourceGroups/$rgName"

# SSH into container (if enabled)
az webapp ssh --name $appName --resource-group $rgName

# Restart the app
az webapp restart --name $appName --resource-group $rgName
```

## 📁 Project Structure

```
.
├── src/                  # Application source code
│   ├── Dockerfile        # Container definition
│   └── ...
├── infra/                # Bicep infrastructure
│   ├── main.bicep        # Main template
│   ├── modules/          # Reusable modules
│   └── README.md         # Infrastructure docs
├── deploy.ps1            # Deployment script
└── azure.yaml            # Azure Developer CLI config
```

## ⚠️ Important Notes

- **No local Docker required** - builds happen in Azure
- **Managed identity** - no passwords needed for ACR
- **AI models** - add separately via Azure Portal (see AI_MODEL_DEPLOYMENT_NOTES.md)
- **Costs** - ~$22-30/month for dev environment

## 🆘 Troubleshooting

### "az: command not found"
Install Azure CLI: https://aka.ms/install-azure-cli

### "azd: command not found"
Install Azure Developer CLI: https://aka.ms/install-azd

### Deploy script fails
Make sure you're logged in:
```powershell
az login
azd auth login
```

### App shows error
Check logs:
```powershell
az webapp log tail --name (azd env get-value AZURE_APP_SERVICE_NAME) --resource-group (azd env get-value AZURE_RESOURCE_GROUP)
```

## 📚 Additional Resources

- [Infrastructure Details](infra/README.md)
- [AI Model Configuration](AI_MODEL_DEPLOYMENT_NOTES.md)
- [GitHub Actions Workflow](.github/workflows/azure-deploy.yml)

---

**Ready to deploy?** Run `.\deploy.ps1` now!
