# GitHub Actions Deployment Setup

This guide explains how to configure GitHub for deploying the ZavaStorefront app to Azure App Service.

## Prerequisites

- Azure subscription with the infrastructure already provisioned (App Service, ACR, Resource Group)
- GitHub repository with this code
- Azure CLI installed locally

## Configure Azure Service Principal

Create a service principal for GitHub Actions to authenticate with Azure:

```bash
# Set your values
SUBSCRIPTION_ID="77a44c96-d4a7-4bf7-94ab-4fe713d97696"
RESOURCE_GROUP="rg-dev"
APP_NAME="ZavaStorefront-GitHub-Actions"

# Create service principal with contributor access
az ad sp create-for-rbac \
  --name $APP_NAME \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP \
  --sdk-auth \
  --json-auth

# Note the output - you'll need: clientId, tenantId, subscriptionId
```

Grant the service principal permission to push to ACR:

```bash
# Get ACR resource ID
ACR_NAME="crf3qfwjs22zbmk"
ACR_ID=$(az acr show --name $ACR_NAME --query id -o tsv)

# Get service principal client ID from previous command output
SP_CLIENT_ID="<client-id-from-previous-output>"

# Assign AcrPush role
az role assignment create \
  --assignee $SP_CLIENT_ID \
  --role AcrPush \
  --scope $ACR_ID
```

## Configure GitHub Variables

Navigate to your repository → Settings → Secrets and variables → Actions → Variables tab.

Create these **Variables**:

| Name | Value | Example |
|------|-------|---------|
| `AZURE_CLIENT_ID` | Service principal client ID | From `az ad sp create-for-rbac` output |
| `AZURE_TENANT_ID` | Azure tenant ID | From `az ad sp create-for-rbac` output |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID | `77a44c96-d4a7-4bf7-94ab-4fe713d97696` |
| `AZURE_WEBAPP_NAME` | App Service name | `app-f3qfwjs22zbmk` |
| `AZURE_RESOURCE_GROUP` | Resource group name | `rg-dev` |
| `AZURE_CONTAINER_REGISTRY` | ACR name (no .azurecr.io) | `crf3qfwjs22zbmk` |

## Trigger Deployment

The workflow runs automatically on:
- Push to `main` branch
- Manual trigger via Actions tab → "Build and Deploy to Azure App Service" → Run workflow

## Verify Deployment

After the workflow completes successfully, access your application at:

`https://<AZURE_WEBAPP_NAME>.azurewebsites.net`

## Troubleshooting

**Authentication fails**: Verify the service principal has the correct roles and the GitHub variables match the `az ad sp create-for-rbac` output.

**ACR push fails**: Ensure the service principal has `AcrPush` role on the container registry.

**App doesn't start**: Check App Service logs with:
```bash
az webapp log tail --name <AZURE_WEBAPP_NAME> --resource-group <AZURE_RESOURCE_GROUP>
```
