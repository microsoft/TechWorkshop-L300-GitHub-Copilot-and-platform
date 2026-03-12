# Workflow Setup

`deploy.yml` builds the container image via ACR Tasks and deploys it to App Service on every push to `main`.
It uses OpenID Connect (OIDC) — no long-lived credentials are stored.

## One-time Azure setup

### 1. Create an app registration and federated credential

```bash
# Create the app registration
az ad app create --display-name "zava-storefront-cicd"

# Note the appId from the output, then create a service principal
az ad sp create --id <appId>

# Add a federated credential (replace ORG/REPO with your GitHub org and repo name)
az ad app federated-credential create --id <appId> --parameters '{
  "name": "github-actions",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:ORG/REPO:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}'
```

### 2. Grant required roles

```bash
ACR_ID=$(az acr show --name <ACR_NAME> --query id -o tsv)
APP_ID=$(az webapp show --name <APP_SERVICE_NAME> --resource-group <RESOURCE_GROUP> --query id -o tsv)
SP_ID=$(az ad sp show --id <appId> --query id -o tsv)

# Push images to ACR
az role assignment create --assignee $SP_ID --role AcrPush --scope $ACR_ID

# Update App Service container settings
az role assignment create --assignee $SP_ID --role "Website Contributor" --scope $APP_ID
```

## GitHub Secrets

Navigate to **Settings → Secrets and variables → Actions → Secrets** and add:

| Secret | Where to find it |
|---|---|
| `AZURE_CLIENT_ID` | App registration → **Application (client) ID** |
| `AZURE_TENANT_ID` | Azure Active Directory → **Tenant ID** |
| `AZURE_SUBSCRIPTION_ID` | Subscriptions → **Subscription ID** |

## GitHub Variables

Navigate to **Settings → Secrets and variables → Actions → Variables** and add:

| Variable | Example value | How to find it |
|---|---|---|
| `ACR_NAME` | `acrzava12ab34cd` | `az acr list -o table` or Bicep output `acrName` |
| `APP_SERVICE_NAME` | `app-zava-dev-a1b2c3` | `az webapp list -o table` or Bicep output `appName` |
| `AZURE_RESOURCE_GROUP` | `rg-zava-dev` | Azure portal or `az group list -o table` |

> **Tip:** After running `azd provision`, get all three values in one command:
> ```bash
> azd env get-values
> ```
> Look for `AZURE_CONTAINER_REGISTRY_NAME`, `SERVICE_WEB_NAME`, and `AZURE_RESOURCE_GROUP`.
