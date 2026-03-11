# CI/CD: Build and Deploy to Azure App Service

The workflow in `.github/workflows/build-deploy.yml` builds the container image in ACR and deploys it to Azure App Service on every push to `main` (when `src/` changes) or via manual dispatch.

## Prerequisites

1. Infrastructure deployed via `azd up` or the Bicep templates in `infra/`.
2. A Microsoft Entra ID app registration with federated credentials for GitHub Actions OIDC.

## Create the Federated Credential

```bash
# Create an app registration (or use an existing one)
az ad app create --display-name "github-zavastore-deploy"

# Note the appId from the output, then create a service principal
az ad sp create --id <APP_ID>

# Grant the service principal Contributor + AcrPush on your resource group
az role assignment create --assignee <APP_ID> --role Contributor --scope /subscriptions/<SUB_ID>/resourceGroups/<RG_NAME>
az role assignment create --assignee <APP_ID> --role AcrPush --scope /subscriptions/<SUB_ID>/resourceGroups/<RG_NAME>

# Add a federated credential for the main branch
az ad app federated-credential create --id <APP_ID> --parameters '{
  "name": "github-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:<GITHUB_ORG>/<GITHUB_REPO>:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}'
```

## Configure GitHub Secrets

Go to **Settings → Secrets and variables → Actions → Secrets** and add:

| Secret                    | Value                                       |
| ------------------------- | ------------------------------------------- |
| `AZURE_CLIENT_ID`        | Application (client) ID of the app registration |
| `AZURE_TENANT_ID`        | Directory (tenant) ID                       |
| `AZURE_SUBSCRIPTION_ID`  | Azure subscription ID                       |

## Configure GitHub Variables

Go to **Settings → Secrets and variables → Actions → Variables** and add:

| Variable              | Value                                                        |
| --------------------- | ------------------------------------------------------------ |
| `ACR_NAME`            | Name of your Azure Container Registry (e.g. `acrzavastoredevxyz`) |
| `AZURE_RESOURCE_GROUP`| Resource group containing the App Service and ACR            |
| `AZURE_WEBAPP_NAME`   | Name of the App Service (e.g. `app-zavastore-dev-xyz`)       |

> **Tip:** After running `azd up`, get the actual resource names from the deployment outputs or the Azure portal.

Once the required secrets and variables are configured, pushes to `main` (or a manual workflow dispatch) will build and deploy the container image to Azure App Service.
