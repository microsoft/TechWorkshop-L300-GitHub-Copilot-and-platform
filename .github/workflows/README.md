# GitHub Actions Deployment Setup

## Required Secrets

Configure these in **Settings → Secrets and variables → Actions → Secrets**:

| Secret | Description |
|--------|-------------|
| `AZURE_CREDENTIALS` | Service principal JSON for Azure login |
| `ACR_USERNAME` | Azure Container Registry username |
| `ACR_PASSWORD` | Azure Container Registry password |

### Creating AZURE_CREDENTIALS

```bash
az ad sp create-for-rbac --name "github-actions-sp" --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group} \
  --json-auth
```

Copy the entire JSON output as the `AZURE_CREDENTIALS` secret value.

### Getting ACR Credentials

```bash
az acr credential show --name {your-acr-name}
```

Use `username` for `ACR_USERNAME` and one of the passwords for `ACR_PASSWORD`.

## Required Variables

Configure these in **Settings → Secrets and variables → Actions → Variables**:

| Variable | Example |
|----------|---------|
| `AZURE_WEBAPP_NAME` | `app-zavastore-dev` |
| `ACR_LOGIN_SERVER` | `crzavastore.azurecr.io` |
