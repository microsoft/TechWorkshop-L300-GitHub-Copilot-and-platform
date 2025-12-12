# Minimal App Service (Container) Workflow

This repository includes a minimal GitHub Actions workflow that:
- Builds the Docker image in Azure Container Registry (ACR) using `az acr build`.
- Points the existing Azure App Service (Linux, Web App for Containers) to the new image.
- Restarts the Web App.

## Configure GitHub Secrets (OIDC)
Set these repository secrets for Azure login via OpenID Connect:
- `AZURE_CLIENT_ID`: Client ID of the Entra app (federated credential for GitHub).
- `AZURE_TENANT_ID`: Your Entra tenant ID.
- `AZURE_SUBSCRIPTION_ID`: Azure subscription ID.

Grant your Entra app `Contributor` on the resource group used by this app or on the specific resources (ACR and Web App).

## Configure GitHub Variables
Set these repository variables to wire the workflow to your resources:
- `AZ_RESOURCE_GROUP`: Resource group name, e.g., `rg-dev`.
- `AZ_WEBAPP_NAME`: Web App name, e.g., `app-duidxq2srj2z`.
- `AZ_ACR_NAME`: ACR name, e.g., `acrduidxq2srj2z`.
- `AZ_IMAGE_NAME`: Image repository name in ACR, e.g., `zavastorefont`.
- `AZ_IMAGE_TAG`: Image tag, e.g., `latest`.

## Workflow Behavior
- Triggers on push to `main` when app or workflow files change.
- Logs into Azure using OIDC (no secrets beyond subscription/tenant/client IDs).
- Resolves the ACR login server and builds the image using ACR cloud build.
- Configures the Web App to pull the image directly from ACR (managed identity on the Web App handles pull permissions).

## Permissions
The workflow requests these repository-level permissions:
- `id-token: write` (for OIDC)
- `contents: read`

## Notes
- Ensure your App Service is configured for port `8080` (`WEBSITES_PORT=8080`), which the app uses.
- The workflow uses `az webapp config container set` to set `DOCKER_CUSTOM_IMAGE_NAME` to `DOCKER|<acr login server>/<image>:<tag>`.
- If you change the image name or tag, update `AZ_IMAGE_NAME` and `AZ_IMAGE_TAG` variables accordingly.
# GitHub Actions Workflow

Minimal workflow to build and deploy the ZavaStorefront .NET app as a container.

## Required GitHub Secrets

Configure these secrets in your repository settings (Settings → Secrets and variables → Actions → New repository secret):

| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `AZURE_CLIENT_ID` | Service principal client ID | From Azure AD app registration |
| `AZURE_TENANT_ID` | Azure AD tenant ID | From Azure AD or `az account show` |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID | From `az account show` or Azure Portal |

## Required GitHub Variables

Configure these variables in your repository settings (Settings → Secrets and variables → Actions → Variables tab → New repository variable):

| Variable Name | Description | Example |
|---------------|-------------|----------|
| `AZURE_CONTAINER_REGISTRY` | ACR name (without .azurecr.io) | `acrduidxq2srj2z` |
| `AZURE_RESOURCE_GROUP` | Resource group name | `rg-dev` |
| `AZURE_APP_SERVICE_NAME` | App Service name | `app-duidxq2srj2z` |

## Setup Steps

### 1. Create Azure Service Principal with Federated Credentials

```bash
# Get your subscription ID
az account show --query id -o tsv

# Create service principal and configure federated identity
az ad sp create-for-rbac \
  --name "github-zavastorefront" \
  --role contributor \
  --scopes /subscriptions/{YOUR_SUBSCRIPTION_ID}/resourceGroups/{YOUR_RESOURCE_GROUP}

# Note the appId (client ID) and tenant from output
```

### 2. Add Federated Credential

```bash
az ad app federated-credential create \
  --id {APP_ID_FROM_ABOVE} \
  --parameters '{
    "name": "github-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:{YOUR_GITHUB_ORG}/{YOUR_REPO}:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### 3. Add Secrets to GitHub

1. Go to your repository → Settings → Secrets and variables → Actions
2. Add the three secrets listed above
3. Switch to the "Variables" tab and add the three variables

## Usage

- **Automatic**: Pushes to `main` branch trigger deployment
- **Manual**: Actions tab → Select workflow → Run workflow

## Getting Resource Names

If you don't know your Azure resource names:

```bash
# List resource groups
az group list --query "[].name" -o tsv

# List App Services in resource group
az webapp list -g {RESOURCE_GROUP} --query "[].name" -o tsv

# List container registries
az acr list --query "[].name" -o tsv
```
