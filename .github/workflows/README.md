# GitHub Actions Deployment Setup

## Required Secrets

Configure these in **Settings → Secrets and variables → Actions → Secrets**:

| Secret | Description |
|--------|-------------|
| `AZURE_CREDENTIALS` | Service principal JSON for Azure login (see below) |
| `ACR_USERNAME` | Azure Container Registry admin username |
| `ACR_PASSWORD` | Azure Container Registry admin password |

### Create AZURE_CREDENTIALS

```bash
az ad sp create-for-rbac --name "github-actions-sp" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group} \
  --sdk-auth
```

Copy the entire JSON output as the secret value.

### Get ACR Credentials

```bash
az acr credential show --name {acr-name}
```

## Required Variables

Configure these in **Settings → Secrets and variables → Actions → Variables**:

| Variable | Description | Example |
|----------|-------------|---------|
| `AZURE_APP_SERVICE_NAME` | Name of your App Service | `app-zavastorefront-abc123` |
| `AZURE_CONTAINER_REGISTRY_NAME` | Name of your ACR (without .azurecr.io) | `acrzavastorefrontabc123` |

Get these values from your AZD outputs:

```bash
azd env get-values
```
