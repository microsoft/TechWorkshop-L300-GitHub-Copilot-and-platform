# CI/CD Pipeline

## GitHub Actions Workflow

The workflow in `.github/workflows/build-deploy.yml` builds the container image using ACR Tasks and deploys it to Azure App Service on every push to `main`.

## Required Configuration

### Secret

| Name | Description | How to create |
|------|-------------|---------------|
| `AZURE_CREDENTIALS` | Service principal JSON for Azure login | See below |

Create the service principal (replace the placeholder values):

```bash
az ad sp create-for-rbac \
  --name "github-zavastore" \
  --role Contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP> \
  --json-auth
```

Copy the full JSON output and save it as a repository secret named **AZURE_CREDENTIALS** under **Settings → Secrets and variables → Actions → New repository secret**.

### Variables

Create these as **repository variables** (not secrets) under **Settings → Secrets and variables → Actions → Variables**:

| Name | Description | Example |
|------|-------------|---------|
| `ACR_NAME` | Azure Container Registry name (no `.azurecr.io`) | `acrzavastoresinghhadev` |
| `WEBAPP_NAME` | App Service name | `app-zavastore-singhha-dev` |

> The exact resource names are determined by the Bicep parameters in `infra/main.bicep`. After provisioning, run `az webapp list -g <RG> --query "[].name" -o tsv` and `az acr list -g <RG> --query "[].name" -o tsv` to get them.
