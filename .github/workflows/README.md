# GitHub Actions Deployment

## Setup

### 1. Create Azure Service Principal

```bash
az ad sp create-for-rbac --name "github-deploy" --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group} \
  --sdk-auth
```

### 2. Configure GitHub Secrets

Go to **Settings → Secrets and variables → Actions → Secrets** and add:

| Secret | Value |
|--------|-------|
| `AZURE_CREDENTIALS` | JSON output from step 1 |

### 3. Configure GitHub Variables

Go to **Settings → Secrets and variables → Actions → Variables** and add:

| Variable | Example |
|----------|---------|
| `ACR_NAME` | `crzavastorelpxiuallxmbgs` |
| `CONTAINER_APP_NAME` | `ca-zavastore-dev` |
| `RESOURCE_GROUP` | `rg-zavastore-dev-eastus2` |

Get values from `azd env get-values` after provisioning.
