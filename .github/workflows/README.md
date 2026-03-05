# Build & Deploy Workflow

The workflow in `.github/workflows/build-deploy.yml` builds a Docker image, pushes it to Azure Container Registry, and deploys it to App Service on every push to `main` (or via manual dispatch).

## Prerequisites

### 1. Create a Service Principal with JSON Credentials

```bash
# Create a service principal with Contributor access to your resource group
az ad sp create-for-rbac --name "github-actions-sp" \
  --role Contributor \
  --scopes /subscriptions/<SUB_ID>/resourceGroups/rg-zava-labs \
  --json-auth

# Grant AcrPush on your resource group
az role assignment create --assignee <APP_ID> --role AcrPush --scope /subscriptions/<SUB_ID>/resourceGroups/rg-zava-labs
```

### 2. Configure GitHub Secrets

Go to **Settings → Secrets and variables → Actions → Secrets** and add:

| Secret | Value |
|---|---|
| `AZURE_CREDENTIALS` | The entire JSON output from the `az ad sp create-for-rbac` command |

### 3. Configure GitHub Variables

Go to **Settings → Secrets and variables → Actions → Variables** and add:

| Variable | Value |
|---|---|
| `AZURE_ACR_NAME` | Your ACR name (e.g. `acrzavastoreiqxzq7aq4fwu4`) |
| `AZURE_WEBAPP_NAME` | Your App Service name (e.g. `app-zavastore-zava-labs-iqxzq7aq4fwu4`) |

### 4. Run

Push to `main` or trigger manually from the **Actions** tab.

> **NOTE** The workflow pushes container images to both Azure Container Registry (ACR) and GitHub Container Registry (GHCR). The `packages: write` permission in the workflow enables GHCR pushes. You may see container packages appear under your repository's Packages tab — this is expected.
