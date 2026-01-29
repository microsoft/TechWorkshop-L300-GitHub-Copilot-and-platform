# GitHub Actions Deployment Setup

## Prerequisites

- Azure subscription with deployed infrastructure (Container Registry and Container App)
- GitHub repository with appropriate permissions

## Configuration Steps

### 1. Create Azure Service Principal

Run this command in Azure CLI to create a service principal with contributor access:

```bash
az ad sp create-for-rbac \
  --name "github-actions-zavastore" \
  --role contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP> \
  --json-auth
```

Copy the entire JSON output for the next step.

### 2. Configure GitHub Secrets

Navigate to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**

#### Add Secret:

| Name | Value | Example |
|------|-------|---------|
| `AZURE_CREDENTIALS` | JSON output from service principal creation | `{"clientId": "...", "clientSecret": "...", ...}` |

### 3. Configure GitHub Variables

In the same **Actions** section, switch to the **Variables** tab:

| Name | Value | Example |
|------|-------|---------|
| `AZURE_CONTAINER_REGISTRY` | ACR name (without .azurecr.io) | `cramubkqos56puq` |
| `AZURE_CONTAINER_APP_NAME` | Container App name | `src` |
| `AZURE_RESOURCE_GROUP` | Resource group name | `rg-dev` |

### 4. Trigger Deployment

The workflow triggers automatically on push to `main` branch, or manually via:
- GitHub → **Actions** → **Build and Deploy** → **Run workflow**

## Current Values

Based on your deployed infrastructure:

- **Container Registry**: `cramubkqos56puq`
- **Container App**: `src`
- **Resource Group**: `rg-dev`
- **Subscription ID**: `b7b6dce1-bd42-4a42-8999-57b145d6e140`
- **Location**: `westus2`

## Verify Deployment

After successful deployment, access your application at:
https://src.bluedune-a37f3a2c.westus2.azurecontainerapps.io/
