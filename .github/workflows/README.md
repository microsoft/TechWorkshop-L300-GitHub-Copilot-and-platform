# GitHub Actions Deployment Setup

## Required Secrets

Configure these in **Settings > Secrets and variables > Actions > Secrets**:

| Secret | Description |
|--------|-------------|
| `AZURE_CREDENTIALS` | Azure service principal JSON (see below) |
| `ACR_USERNAME` | Azure Container Registry username |
| `ACR_PASSWORD` | Azure Container Registry password |

### Create Azure Service Principal

```bash
az ad sp create-for-rbac --name "github-actions-sp" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/rg-dev \
  --json-auth
```

Copy the entire JSON output to `AZURE_CREDENTIALS` secret.

### Get ACR Credentials

```bash
az acr credential show --name {acr-name}
```

Use `username` for `ACR_USERNAME` and `password` for `ACR_PASSWORD`.

## Required Variables

Configure these in **Settings > Secrets and variables > Actions > Variables**:

| Variable | Example |
|----------|---------|
| `AZURE_WEBAPP_NAME` | `app-xbpvytnzezeiq` |
| `ACR_LOGIN_SERVER` | `crxbpvytnzezeiq.azurecr.io` |

### Get Variable Values

```bash
azd env get-values
```

Use `SERVICE_WEB_NAME` for `AZURE_WEBAPP_NAME` and `ACR_LOGIN_SERVER` for `ACR_LOGIN_SERVER`.
