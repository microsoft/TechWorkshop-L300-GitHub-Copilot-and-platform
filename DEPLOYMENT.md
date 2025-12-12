# GitHub Actions Deployment Setup

This repository includes a GitHub Actions workflow that automatically builds and deploys the ZavaStorefront application to Azure Container Apps.

## Prerequisites

- Azure subscription with the following resources already deployed:
  - Resource Group: `rg-workshop-l300`
  - Azure Container Registry: `crmzcdesoprdj4i`
  - Azure Container App: `src`

## GitHub Configuration

### Required Secrets

Configure the following secrets in your GitHub repository settings (**Settings** → **Secrets and variables** → **Actions** → **New repository secret**):

1. **`AZURE_CREDENTIALS`**
   
   Create an Azure service principal with contributor access to your resource group:
   
   ```bash
   az ad sp create-for-rbac \
     --name "github-actions-zava-storefront" \
     --role Contributor \
     --scopes /subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/rg-workshop-l300 \
     --json-auth
   ```
   
   Copy the entire JSON output and paste it as the secret value.

2. **`AZURE_CONTAINER_REGISTRY_NAME`**
   
   Value: `crmzcdesoprdj4i`

## Workflow Trigger

The workflow runs automatically on:
- Push to the `main` branch
- Manual trigger via GitHub Actions UI (workflow_dispatch)

## Deployment Process

The workflow performs the following steps:
1. Checks out the code
2. Logs in to Azure using the service principal credentials
3. Logs in to Azure Container Registry
4. Builds the Docker image from the `src` directory
5. Pushes the image with both SHA and latest tags
6. Updates the Container App with the new image

## Monitoring

- View workflow runs: **Actions** tab in your GitHub repository
- View deployed application: https://src.salmonbeach-1c2f8dad.eastus2.azurecontainerapps.io/
- View Azure resources: [Azure Portal](https://portal.azure.com/#@/resource/subscriptions/f463a64a-823c-4280-8756-39aee9e01f6d/resourceGroups/rg-workshop-l300/overview)
