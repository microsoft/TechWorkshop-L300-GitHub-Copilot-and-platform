# GitHub Actions Deployment Setup

## Prerequisites
- Azure resources deployed (ACR, Container App, Resource Group)
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
| `ACR_NAME` | Azure Container Registry name (without .azurecr.io) | `crn1a2b3c4d5e` |
| `CONTAINER_APP_NAME` | Azure Container App name | `app1a2b3c4d5e` |
| `RESOURCE_GROUP` | Azure Resource Group name | `my-rg` |

## Grant ACR Access to Container App

The role assignment is configured automatically by the Bicep infrastructure, but verify it's in place:

```bash
# Verify the Container App can pull from ACR
az role assignment list \
  --assignee {container-app-principal-id} \
  --scope {acr-resource-id}
```

## Trigger Deployment

Push to the `main` branch or manually trigger the workflow from the **Actions** tab to deploy.
