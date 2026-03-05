# GitHub Actions Deployment Setup

This repository contains a GitHub Actions workflow that automatically builds and deploys your .NET application as a container to Azure App Service.

## Prerequisites

Before the workflow can run successfully, you need to configure the following GitHub secrets and variables:

### Required GitHub secrets

1. **AZURE_CLIENT_ID** – The client ID (app ID) of your Azure service principal
2. **AZURE_TENANT_ID** – The tenant ID of your Azure Active Directory
3. **AZURE_CLIENT_SECRET** – The client secret of your Azure service principal
4. **AZURE_SUBSCRIPTION_ID** – Your Azure subscription ID

   To create a service principal and obtain these values:

   ```bash
   # Create a service principal with contributor access to your resource group
   az ad sp create-for-rbac --name "github-actions-sp" \
     --role Contributor \
     --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group-name}
   ```

   The output will contain `appId` (→ `AZURE_CLIENT_ID`), `tenant` (→ `AZURE_TENANT_ID`), and `password` (→ `AZURE_CLIENT_SECRET`).
   Set `AZURE_SUBSCRIPTION_ID` to your Azure subscription ID.

### Required GitHub variables

1. **AZURE_CONTAINER_REGISTRY_NAME** – The name of your Azure Container Registry (without .azurecr.io)
2. **AZURE_APP_SERVICE_NAME** – The name of your Azure App Service

### How to configure secrets and variables

1. Go to your GitHub repository
2. Click on **Settings → Secrets and variables → Actions**
3. Add the secret under the **Secrets** tab
4. Add the variables under the **Variables** tab

## Service principal permissions

The service principal needs the following permissions:

- **Contributor** role on the resource group (for App Service deployment)
- **AcrPush** role on the Azure Container Registry (for pushing container images)

To assign the ACR role:

```bash
az role assignment create \
  --assignee {service-principal-client-id} \
  --role AcrPush \
  --scope /subscriptions/{subscription-id}/resourceGroups/{resource-group-name}/providers/Microsoft.ContainerRegistry/registries/{acr-name}
```

## Workflow Behavior

The workflow triggers on:

- Push to `main` branch
- Pull requests to `main` branch
- Manual trigger via GitHub UI

The workflow will:

1. Build your .NET application as a Docker container
2. Push the container to your Azure Container Registry
3. Deploy the container to your Azure App Service

## Finding Your Resource Names

You can find your resource names by running:

```bash
# List your resource groups
az group list --output table

# List resources in your resource group
az resource list --resource-group {your-resource-group-name} --output table
```

Look for resources with types:

- `Microsoft.ContainerRegistry/registries` (for ACR name)
- `Microsoft.Web/sites` (for App Service name)
