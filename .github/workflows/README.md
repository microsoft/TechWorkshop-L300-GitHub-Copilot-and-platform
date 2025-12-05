# GitHub Actions Deployment Setup

This workflow automatically builds and deploys the ZavaStorefront .NET application as a container to Azure App Service.

## Prerequisites

- Azure subscription with deployed infrastructure (run `azd provision` first)
- GitHub repository with this workflow file

## Required Secrets

### AZURE_CREDENTIALS

Create an Azure service principal with contributor access to your resource group:

```bash
az ad sp create-for-rbac --name "github-actions-zavastore" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group-name} \
  --json-auth
```

Copy the entire JSON output and add it as a secret named `AZURE_CREDENTIALS` in your GitHub repository.

**To add the secret:**
1. Go to your repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `AZURE_CREDENTIALS`
4. Value: Paste the JSON output from the command above

## Required Variables

### AZURE_CONTAINER_REGISTRY_NAME

The name of your Azure Container Registry (without `.azurecr.io`)

**To find it:**
```bash
azd env get-value AZURE_CONTAINER_REGISTRY_NAME
```

### AZURE_WEBAPP_NAME

The name of your Azure App Service

**To find it:**
```bash
azd env get-value AZURE_APP_SERVICE_NAME
```

**To add variables:**
1. Go to your repository → Settings → Secrets and variables → Actions → Variables tab
2. Click "New repository variable"
3. Add both variables with their respective values

## Workflow Behavior

- **Triggers on:**
  - Push to `main` or `dev` branches
  - Pull requests to `main`
  - Manual dispatch

- **Steps:**
  1. Checks out code
  2. Logs into Azure
  3. Logs into Azure Container Registry
  4. Builds Docker image and pushes with commit SHA and `latest` tags
  5. Deploys the image to Azure App Service

## First-Time Setup Checklist

- [ ] Run `azd provision` to create Azure infrastructure
- [ ] Create Azure service principal and add `AZURE_CREDENTIALS` secret
- [ ] Add `AZURE_CONTAINER_REGISTRY_NAME` variable
- [ ] Add `AZURE_WEBAPP_NAME` variable
- [ ] Push workflow file to trigger first deployment
