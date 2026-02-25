# CI/CD: Build & Deploy to Azure App Service

The workflow in `.github/workflows/build-deploy.yml` builds the container image and deploys it to Azure App Service on every push to `main`.

## Prerequisites

The workflow authenticates to Azure using **OpenID Connect (OIDC) federated credentials** — no long-lived secrets are stored in GitHub.

You need a Microsoft Entra ID app registration with a federated credential configured for your GitHub repo. See [Azure docs: OIDC with GitHub Actions](https://learn.microsoft.com/azure/developer/github/connect-from-azure?tabs=azure-cli%2Clinux#use-the-azure-login-action-with-openid-connect) for full setup instructions.

The service principal must have the **AcrPush** role on the ACR and **Contributor** (or **Website Contributor**) role on the App Service.

## GitHub Secrets (Settings → Secrets and variables → Actions → Secrets)

| Secret | Description |
|---|---|
| `AZURE_CLIENT_ID` | Application (client) ID of the Entra ID app registration |
| `AZURE_TENANT_ID` | Directory (tenant) ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |

## GitHub Variables (Settings → Secrets and variables → Actions → Variables)

| Variable | Description | Example |
|---|---|---|
| `AZURE_CONTAINER_REGISTRY_NAME` | ACR name (not the full login server) | `acrzava1a2b3c` |
| `AZURE_APP_SERVICE_NAME` | App Service resource name | `app-zava-1a2b3c` |

> **Tip:** After deploying infrastructure with `azd up`, retrieve these values from the outputs:
>
> ```bash
> azd env get-values
> ```
>
> Look for `AZURE_CONTAINER_REGISTRY_NAME` and `AZURE_APP_SERVICE_NAME`.
