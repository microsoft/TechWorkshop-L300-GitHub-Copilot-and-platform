# Deploy Workflow Setup

The `deploy-app.yml` workflow builds the Docker container from `src/` and deploys it to Azure App Service using OIDC (federated credentials) — no passwords to rotate.

## Prerequisites

1. **Azure resources provisioned** — run `azd up` or deploy the Bicep in `infra/` first.
2. **Microsoft Entra ID app registration** with a federated credential for GitHub Actions.

## Create the App Registration & Federated Credential

```bash
# Create a service principal and note the appId and tenant
az ad app create --display-name "github-deploy-zava"
APP_ID=$(az ad app list --display-name "github-deploy-zava" --query "[0].appId" -o tsv)
az ad sp create --id $APP_ID

# Grant Contributor on the resource group (adjust name as needed)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
az role assignment create \
  --assignee $APP_ID \
  --role Contributor \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/<YOUR_RESOURCE_GROUP>

# Also grant AcrPush so the workflow can push images
ACR_ID=$(az acr show --name <YOUR_ACR_NAME> --query id -o tsv)
az role assignment create \
  --assignee $APP_ID \
  --role AcrPush \
  --scope $ACR_ID

# Add OIDC federated credential for the main branch
az ad app federated-credential create --id $APP_ID --parameters '{
  "name": "github-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:<OWNER>/<REPO>:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}'
```

## Configure GitHub Secrets and Variables

The workflow reads sensitive credentials from **repository secrets** and resource names from **repository variables**. You must add all six values below.

### Step 1 — Add Repository Secrets

1. Open your GitHub repository in a browser.
2. Go to **Settings** → **Secrets and variables** → **Actions**.
3. Select the **Secrets** tab, then click **New repository secret**.
4. Add each of the following (one at a time):

| Secret name             | Where to find the value                                                    |
| ----------------------- | -------------------------------------------------------------------------- |
| `AZURE_CLIENT_ID`      | The **Application (client) ID** from the app registration you created above |
| `AZURE_TENANT_ID`      | Run `az account show --query tenantId -o tsv`                              |
| `AZURE_SUBSCRIPTION_ID`| Run `az account show --query id -o tsv`                                    |

### Step 2 — Add Repository Variables

1. On the same **Settings → Secrets and variables → Actions** page, switch to the **Variables** tab.
2. Click **New repository variable** and add each of the following:

| Variable name          | Where to find the value                               | Example                  |
| ---------------------- | ----------------------------------------------------- | ------------------------ |
| `ACR_NAME`             | Container registry name (Bicep/azd output)            | `crzavadevk7m3`          |
| `AZURE_RESOURCE_GROUP` | Resource group name (Bicep/azd output)                | `rg-zava-dev-k7m3`      |
| `WEBAPP_NAME`          | App Service web app name (Bicep/azd output)           | `app-zava-dev-k7m3-brbrk4` |

> **Tip:** After `azd up`, retrieve all three variable values at once with:
> ```bash
> azd env get-values
> ```
> Look for `AZURE_RESOURCE_GROUP`, `AZURE_CONTAINER_REGISTRY_NAME`, and the app name in `WEB_URL`.

## Trigger

The workflow runs automatically on pushes to `main` that change files in `src/` and can also be triggered manually via **Actions → Build and Deploy → Run workflow**.
