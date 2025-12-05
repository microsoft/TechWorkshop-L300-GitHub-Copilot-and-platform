# GitHub Actions Deployment Setup

## Required Secrets

Configure these in **Settings → Secrets and variables → Actions → Secrets**:

| Secret | Description |
|--------|-------------|
| `AZURE_CLIENT_ID` | Service principal Application (client) ID |
| `AZURE_TENANT_ID` | Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |
| `ACR_USERNAME` | Azure Container Registry admin username |
| `ACR_PASSWORD` | Azure Container Registry admin password |

### Setup Federated Credentials for GitHub Actions

1. Go to Azure Portal → Microsoft Entra ID → App registrations
2. Find `github-actions-sp` and click on it
3. Go to **Certificates & secrets** → **Federated credentials** → **Add credential**
4. Select **GitHub Actions deploying Azure resources**
5. Fill in:
   - **Organization**: `VaasInc`
   - **Repository**: `TechWorkshop-L300-GitHub-Copilot-and-platform`
   - **Entity type**: `Branch`
   - **Branch**: `main` (repeat for `dev` if needed)
   - **Name**: `github-actions-main`

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
