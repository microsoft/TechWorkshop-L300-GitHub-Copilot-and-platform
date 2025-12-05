# GitHub Actions Configuration Guide

This guide explains how to configure GitHub secrets and variables for the automated deployment workflow.

## Required GitHub Secrets

Configure the following secrets in your repository at **Settings → Security → Secrets and variables → Actions → New repository secret**.

### 1. AZURE_CREDENTIALS

Service principal credentials for Azure authentication.

**Create the service principal:**
```bash
az ad sp create-for-rbac \
  --name "github-actions-zavasf-dev" \
  --role contributor \
  --scopes /subscriptions/b839a057-09ec-4b05-9c66-3e9f5541efb3/resourceGroups/rg-zavasf-dev \
  --json-auth
```

Copy the entire JSON output and save it as the `AZURE_CREDENTIALS` secret.

Expected format:
```json
{
  "clientId": "<client-id>",
  "clientSecret": "<client-secret>",
  "subscriptionId": "b839a057-09ec-4b05-9c66-3e9f5541efb3",
  "tenantId": "<tenant-id>"
}
```

### 2. REGISTRY_USERNAME

Azure Container Registry admin username.

**Get the username:**
```bash
az acr credential show --name azacrf637bz3ntw4dk --query "username" -o tsv
```

**Note:** If admin account is disabled, enable it first:
```bash
az acr update --name azacrf637bz3ntw4dk --admin-enabled true
```

### 3. REGISTRY_PASSWORD

Azure Container Registry admin password.

**Get the password:**
```bash
az acr credential show --name azacrf637bz3ntw4dk --query "passwords[0].value" -o tsv
```

## Resource Information

These values are already configured in the workflow file:

| Resource | Value |
|----------|-------|
| Azure Subscription ID | `b839a057-09ec-4b05-9c66-3e9f5541efb3` |
| Resource Group | `rg-zavasf-dev` |
| Container Registry | `azacrf637bz3ntw4dk` |
| ACR Login Server | `azacrf637bz3ntw4dk.azurecr.io` |
| App Service Name | `azappf637bz3ntw4dk` |
| Image Name | `zavastorefrontapp/web` |

## Service Principal Permissions

The service principal needs the following role assignments:

```bash
# Contributor on resource group (already granted above)
az role assignment create \
  --assignee <client-id> \
  --role Contributor \
  --scope /subscriptions/b839a057-09ec-4b05-9c66-3e9f5541efb3/resourceGroups/rg-zavasf-dev

# AcrPush role for pushing images to ACR
az role assignment create \
  --assignee <client-id> \
  --role AcrPush \
  --scope /subscriptions/b839a057-09ec-4b05-9c66-3e9f5541efb3/resourceGroups/rg-zavasf-dev/providers/Microsoft.ContainerRegistry/registries/azacrf637bz3ntw4dk
```

## Workflow Triggers

The workflow runs automatically when:
- Code is pushed to `main` or `dev` branches
- Manually triggered via **Actions → Build and Deploy to Azure App Service → Run workflow**

## Verifying Deployment

After the workflow completes:

1. Check the Actions tab for workflow status
2. Visit the app at: https://azappf637bz3ntw4dk.azurewebsites.net
3. View container logs:
   ```bash
   az webapp log tail --name azappf637bz3ntw4dk --resource-group rg-zavasf-dev
   ```

## Troubleshooting

**Authentication failures:**
- Verify `AZURE_CREDENTIALS` JSON format is correct
- Ensure service principal has not expired
- Check role assignments are in place

**ACR push failures:**
- Confirm `REGISTRY_USERNAME` and `REGISTRY_PASSWORD` are correct
- Verify ACR admin account is enabled
- Check AcrPush role is assigned to service principal

**Deployment failures:**
- Ensure App Service allows container image pulls from ACR
- Verify managed identity has AcrPull role on the registry
- Check App Service logs for startup errors
