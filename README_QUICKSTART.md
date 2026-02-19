# ZavaStorefront - Quick Start Guide

## Azure Deployment

Deploy the complete ZavaStorefront application infrastructure to Azure in minutes using Azure Developer CLI (AZD).

### Prerequisites
1. [Azure CLI](https://aka.ms/InstallAzureCLIDeb) (version 2.50.0+)
2. [Azure Developer CLI (AZD)](https://aka.ms/install-azd.sh) (version 1.5.0+)
3. Active Azure subscription with permissions to create resources

### Quick Deployment

```bash
# Login to Azure
az login
azd auth login

# Deploy everything (infrastructure + application)
azd up
```

When prompted:
- **Environment name**: `dev` (or your preferred name)
- **Subscription**: Select your Azure subscription
- **Location**: `westus3` (required for AI Hub models)

Deployment takes approximately 10-15 minutes.

### What Gets Deployed

| Resource | Purpose | SKU |
|----------|---------|-----|
| Azure Container Registry | Docker image storage | Basic |
| Linux App Service | Web application hosting | B1 |
| Application Insights | Application monitoring | Pay-as-you-go |
| Log Analytics | Centralized logging | Pay-as-you-go |
| Microsoft Foundry (AI Hub) | GPT-4 & Phi models | Basic |
| Key Vault | Secrets management | Standard |
| Storage Account | Supporting infrastructure | Standard_LRS |

**Region**: West US 3  
**Estimated Monthly Cost**: ~$20-30 USD (excluding AI model usage)

### Key Features

✅ **No Local Docker Required** - Images built in Azure Container Registry  
✅ **RBAC Authentication** - Managed identity, no passwords  
✅ **HTTPS Only** - TLS 1.2+ enforced  
✅ **Monitoring Built-in** - Application Insights integrated  
✅ **AI-Ready** - Microsoft Foundry for GPT-4 and Phi models  

### Verification

Run the verification script to check your deployment:

```bash
./verify-infrastructure.sh
```

### Access Your Application

After deployment completes, access your application at:
```
https://app-zavastore-dev-westus3.azurewebsites.net
```

The exact URL will be displayed in the `azd up` output.

### Documentation

For detailed information, see:
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Comprehensive deployment guide with troubleshooting
- **[SUMMARY.md](SUMMARY.md)** - Complete infrastructure overview
- **[infra/README.md](infra/README.md)** - Detailed infrastructure documentation
- **Main README** - Workshop exercises and lab guide

### Deployment Methods

#### Method 1: AZD (Recommended)
```bash
azd up
```

#### Method 2: Step-by-Step
```bash
azd provision  # Infrastructure only
azd deploy     # Application only
```

#### Method 3: GitHub Actions (CI/CD)
- Configure OIDC credentials (see DEPLOYMENT.md)
- Push to main branch
- Automatic build and deploy

### Common Commands

```bash
# View deployed resources
azd show

# View environment variables
azd env get-values

# Redeploy application only
azd deploy

# View logs
azd monitor

# Delete all resources
azd down --purge
```

### Troubleshooting

**Issue**: Deployment fails with quota error  
**Solution**: Request quota increase or try different region

**Issue**: Container doesn't start  
**Solution**: Check logs with `az webapp log tail`

**Issue**: ACR pull fails  
**Solution**: Verify managed identity and role assignment

For more troubleshooting help, see [DEPLOYMENT.md](DEPLOYMENT.md).

### Next Steps

1. ✅ Deploy infrastructure with `azd up`
2. ✅ Verify resources in Azure Portal
3. ✅ Access your application
4. ✅ Configure AI models in AI Hub (optional)
5. ✅ Set up CI/CD with GitHub Actions (optional)

### Support

- Check [DEPLOYMENT.md](DEPLOYMENT.md) for detailed instructions
- Review Azure Portal activity logs
- Check Application Insights for application diagnostics
- Open GitHub issue for help

---

**Full Lab Documentation**: See [README.md](README.md) for complete workshop exercises
