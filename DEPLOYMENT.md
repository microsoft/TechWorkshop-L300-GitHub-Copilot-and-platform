# Azure Infrastructure Deployment Guide

This guide explains how to deploy the ZavaStorefront application to Azure using Azure Developer CLI (azd).

## Prerequisites

1. Azure CLI installed and logged in
2. Azure Developer CLI (azd) installed  
3. Docker installed (for local testing)
4. An Azure subscription with Owner/Contributor permissions

## Automated Deployment with Azure Developer CLI

The easiest way to deploy is using Azure Developer CLI:

```bash
# Login to Azure
azd auth login

# Initialize and deploy
azd up
```

This will:
- Create all Azure resources
- Build and push the Docker image
- Deploy the application
- Configure Application Insights monitoring

## GitHub Actions Deployment

For automated deployments from GitHub:

1. Create a service principal with appropriate permissions
2. Set up the required secrets in your GitHub repository:
   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID` 
   - `AZURE_SUBSCRIPTION_ID`
   - `ACR_USERNAME`
   - `ACR_PASSWORD` (get from Azure portal or azd output)

3. Push changes to trigger the workflow

## Manual Setup

If you prefer manual setup:

1. Create resource group:
```bash
az group create --name rg-zava-storefront --location westus2
```

2. Deploy infrastructure:
```bash
az deployment group create \
  --resource-group rg-zava-storefront \
  --template-file infra/main.bicep \
  --parameters location=westus2
```

3. Build and push Docker image:
```bash
# Get ACR login server
acrServer=$(az acr list --resource-group rg-zava-storefront --query "[0].loginServer" -o tsv)

# Build and push image
az acr build --registry $acrServer --image zava-storefront:latest src/
```

## Service Principal Setup

If creating a service principal manually for GitHub Actions:

```bash
# Create service principal with OIDC support
az ad sp create-for-rbac \
  --name "ZavaStorefront-GitHub-Actions" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group-name}

# Configure federated identity for GitHub Actions
az ad app federated-credential create \
  --id {app-id} \
  --parameters '{
    "name": "github-actions",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YOUR_USERNAME/YOUR_REPO:ref:refs/heads/main",
    "description": "GitHub Actions OIDC",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

## Application Access

After successful deployment:
- Application URL: Available in azd output or Azure portal
- Application Insights: Monitor performance and logs
- Container Registry: Stores the Docker images

## Troubleshooting

- Verify Azure CLI login: `az account show`
- Check resource permissions: Ensure your account has Contributor role
- Review deployment logs: Use Azure portal Activity Log
- Container logs: Available in App Service Logs section

## Clean Up

To remove all resources:

```bash
azd down
```

Or manually delete the resource group:

```bash
az group delete --name rg-zava-storefront --yes
```
