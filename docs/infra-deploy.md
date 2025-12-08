**Overview**: This document explains how to provision the sample dev environment for `ZavaStorefront` in `westus3`.

- **Environment**: dev
- **Region**: `westus3`

**Required GitHub repository secrets**
- `AZURE_CREDENTIALS` — service principal JSON for `azure/login` in GitHub Actions
- `AZURE_CONTAINER_REGISTRY_NAME` — e.g. `myacr.azurecr.io`
- `AZURE_RESOURCE_GROUP` — resource group name where infra will be created
- `AZURE_APP_SERVICE_NAME` — name for Web App

**Quick provisioning (local dev using azd)**
1. Install `azd` and login: `azd login`
2. Initialize if needed: `azd init` (already configured)
3. Provision resources (preview):

```powershell
azd provision --environment dev --template-path infra --location westus3
```

4. Deploy app (after building/pushing image or using code deploy):

```powershell
azd deploy --environment dev
```

**Notes**
- The scaffold creates ACR, App Service Plan (Linux), Web App (container), Application Insights (workspace-based), Log Analytics, and Key Vault.
- You must provide a roleDefinitionId for AcrPull role assignment if you want the Web App managed identity to pull images from ACR. Alternatively you can enable admin user for ACR (not recommended).
