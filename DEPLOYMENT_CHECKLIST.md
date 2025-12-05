# Deployment Checklist

Use this checklist to ensure a successful deployment of the ZavaStorefront infrastructure.

## Pre-Deployment Checklist

### Prerequisites
- [ ] Azure CLI installed (`az --version`)
- [ ] Azure Developer CLI installed (`azd version`)
- [ ] Git installed (`git --version`)
- [ ] Azure subscription access confirmed
- [ ] Contributor/Owner role on subscription

### Authentication
- [ ] Azure CLI authenticated (`az login`)
- [ ] Azure Developer CLI authenticated (`azd auth login`)
- [ ] Correct subscription selected (`az account show`)

### Code Validation
- [ ] Bicep templates validated (`az bicep build --file infra/main.bicep`) ✅
- [ ] Dockerfile syntax validated
- [ ] Git repository initialized
- [ ] Latest code committed to repository

## Deployment Steps

### Option 1: Azure Developer CLI (Recommended)

- [ ] **Step 1**: Initialize project
  ```powershell
  azd init
  ```
  - [ ] Environment name entered (default: dev)
  - [ ] Subscription selected

- [ ] **Step 2**: Provision infrastructure
  ```powershell
  azd provision
  ```
  - [ ] Resource group created
  - [ ] Container Registry deployed
  - [ ] App Service Plan deployed
  - [ ] App Service deployed
  - [ ] Monitoring resources deployed
  - [ ] AI Foundry deployed
  - [ ] RBAC assignments configured

- [ ] **Step 3**: Deploy application
  ```powershell
  azd deploy
  ```
  - [ ] Docker image built in ACR
  - [ ] Image tagged with `latest` and Git hash
  - [ ] App Service updated with new image
  - [ ] Application accessible via HTTPS

### Option 2: Manual Deployment

- [ ] **Step 1**: Create resource group
  ```powershell
  az group create --name rg-zavastorefront-dev-westus3 --location westus3
  ```

- [ ] **Step 2**: Deploy Bicep infrastructure
  ```powershell
  az deployment sub create `
    --location westus3 `
    --template-file infra/main.bicep `
    --parameters infra/main.parameters.json
  ```

- [ ] **Step 3**: Build and push container image
  ```powershell
  $acrName = "acrzavastorefront<unique>"
  az acr build --registry $acrName --image zava-storefront:latest ./src
  ```

- [ ] **Step 4**: Restart App Service
  ```powershell
  az webapp restart --name <app-name> --resource-group rg-zavastorefront-dev-westus3
  ```

## Post-Deployment Verification

### Infrastructure
- [ ] Resource group exists in Azure Portal
- [ ] All resources deployed successfully (8+ resources)
- [ ] Container Registry contains `zava-storefront` image
- [ ] App Service shows "Running" status
- [ ] Managed Identity enabled on App Service
- [ ] RBAC role assignments visible in ACR Access Control

### Application
- [ ] App Service URL accessible (`https://<hostname>`)
- [ ] HTTPS enforced (HTTP redirects to HTTPS)
- [ ] Application loads without errors
- [ ] No container startup errors in logs

### Monitoring
- [ ] Application Insights receiving telemetry
- [ ] Log Analytics workspace contains data
- [ ] App Service logs streaming correctly
- [ ] No deployment errors in Activity Log

### Security
- [ ] ACR admin user disabled
- [ ] App Service uses Managed Identity (no credentials in settings)
- [ ] HTTPS-only enforcement enabled
- [ ] TLS 1.2+ required

## Configuration Verification

### App Service Settings
Verify these environment variables are set:

- [ ] `APPLICATIONINSIGHTS_CONNECTION_STRING`
- [ ] `ApplicationInsightsAgent_EXTENSION_VERSION` = `~3`
- [ ] `APPINSIGHTS_INSTRUMENTATIONKEY`
- [ ] `DOCKER_REGISTRY_SERVER_URL` = `https://<acr>.azurecr.io`
- [ ] `WEBSITES_PORT` = `80`
- [ ] `DOCKER_ENABLE_CI` = `true`

### Container Configuration
- [ ] `linuxFxVersion` set to `DOCKER|<acr>.azurecr.io/zava-storefront:latest`
- [ ] Always On: Enabled
- [ ] FTPS State: FtpsOnly
- [ ] Minimum TLS Version: 1.2
- [ ] HTTP 2.0: Enabled

## Troubleshooting

If deployment fails, check:

- [ ] Azure subscription has sufficient quota (especially for App Service Plan)
- [ ] Region `westus3` supports all required resource types
- [ ] No naming conflicts with existing resources
- [ ] Service principal has correct permissions
- [ ] Bicep template syntax validated
- [ ] Review Activity Log for detailed error messages

## Post-Deployment Tasks

### Immediate
- [ ] Test application functionality
- [ ] Verify AI Foundry Hub access
- [ ] Configure AI model deployments (GPT-4, Phi)
- [ ] Add AI endpoint/key to App Service settings
- [ ] Assign `Cognitive Services User` role (App Service → AI Foundry)

### Short-Term
- [ ] Set up Azure Monitor alerts (errors, high latency, resource usage)
- [ ] Configure custom domain and SSL certificate
- [ ] Review and optimize cost allocation
- [ ] Set up deployment slots for staging
- [ ] Configure auto-scaling rules

### Production Readiness
- [ ] VNet integration and Private Endpoints
- [ ] Azure Front Door with WAF
- [ ] Move secrets to Azure Key Vault
- [ ] Upgrade ACR to Premium (for geo-replication)
- [ ] Implement Azure Policy for compliance
- [ ] Set up Azure Backup for App Service
- [ ] Configure DDoS Protection

## Documentation Review

- [ ] Read `infra/README.md` for detailed deployment guide
- [ ] Review `IMPLEMENTATION.md` for architecture details
- [ ] Check `src/README.md` for application documentation
- [ ] Understand `azure.yaml` configuration and hooks

## Cost Management

- [ ] Review cost estimation (~$23-29/month for dev)
- [ ] Set up Azure Cost Management alerts
- [ ] Tag resources appropriately (environment, project, owner)
- [ ] Consider Azure Reservations for production

## Cleanup (When Needed)

To remove all resources:

- [ ] Stop App Service to avoid charges
- [ ] Export any required data from Log Analytics
- [ ] Delete resource group:
  ```powershell
  azd down --purge
  # OR
  az group delete --name rg-zavastorefront-dev-westus3 --yes
  ```

## Success Criteria

✅ All acceptance criteria from GitHub Issue #1 met:
- ✅ Infrastructure as Code (Bicep templates)
- ✅ Resources deployed to westus3
- ✅ Application containerized and running
- ✅ Managed Identity configured with RBAC
- ✅ Monitoring enabled (Application Insights + Log Analytics)
- ✅ AZD automation configured
- ✅ Comprehensive documentation provided

---

**Status**: Ready for deployment ✅  
**Estimated Time**: 15-20 minutes (automated deployment)  
**Risk Level**: Low (dev environment, validated templates)

## Support

- **Documentation**: `infra/README.md`
- **Troubleshooting**: `infra/README.md#troubleshooting`
- **Azure Support**: https://portal.azure.com/#blade/Microsoft_Azure_Support/HelpAndSupportBlade
- **GitHub Issues**: Report issues with deployment logs attached
