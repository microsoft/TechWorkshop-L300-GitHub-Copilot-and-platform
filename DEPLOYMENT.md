# GitHub Actions Deployment Setup

## Prerequisites
- Azure resources deployed (ACR, App Service, Resource Group)
- GitHub repository with admin access

## Configure GitHub Secrets

### 1. Create Azure Service Principal
Run the following Azure CLI command to create a service principal with Contributor access:

```bash
az ad sp create-for-rbac \
  --name "github-actions-sp" \
  --role Contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group-name} \
  --sdk-auth
```

Copy the entire JSON output.

### 2. Add GitHub Secret
1. Navigate to your GitHub repository
2. Go to **Settings** > **Secrets and variables** > **Actions**
3. Click **New repository secret**
4. Name: `AZURE_CREDENTIALS`
5. Value: Paste the JSON output from step 1
6. Click **Add secret**

## Configure GitHub Variables

Add the following repository variables in **Settings** > **Secrets and variables** > **Actions** > **Variables**:

| Variable Name | Description | Example |
|--------------|-------------|---------|
| `ACR_NAME` | Azure Container Registry name (without .azurecr.io) | `myacrname` |
| `WEBAPP_NAME` | Azure App Service name | `mywebapp` |
| `RESOURCE_GROUP` | Azure Resource Group name | `my-rg` |

## Grant ACR Access to App Service

After deployment, grant the App Service managed identity access to pull from ACR:

```bash
# Get the App Service principal ID
PRINCIPAL_ID=$(az webapp identity show \
  --name {webapp-name} \
  --resource-group {resource-group-name} \
  --query principalId -o tsv)

# Get the ACR resource ID
ACR_ID=$(az acr show \
  --name {acr-name} \
  --query id -o tsv)

# Assign AcrPull role
az role assignment create \
  --assignee $PRINCIPAL_ID \
  --role AcrPull \
  --scope $ACR_ID
```

## Trigger Deployment

Push to the `main` branch or manually trigger the workflow from the **Actions** tab to deploy.
