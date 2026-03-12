# Deploy Workflow

Builds the container image from `src/` and deploys it to the Azure Web App defined in the `infra/` folder.

## Prerequisites

1. **Deploy infrastructure first** — run the Bicep templates in `infra/` to create the resource group, ACR, App Service, etc.
2. **Create an Entra ID app registration** with federated credentials for GitHub Actions OIDC:
   - Federation subject: `repo:<owner>/<repo>:ref:refs/heads/main`
   - Grant the service principal **Contributor** on the resource group and **AcrPush** on the container registry.

## GitHub Secrets (Settings → Secrets and variables → Actions → Secrets)

| Secret | Description |
|---|---|
| `AZURE_CLIENT_ID` | Application (client) ID of the Entra app registration |
| `AZURE_TENANT_ID` | Directory (tenant) ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |

## GitHub Variables (Settings → Secrets and variables → Actions → Variables)

| Variable | Description | Example |
|---|---|---|
| `ACR_NAME` | Name of the Azure Container Registry (not the full login server) | `zavastoredev7x2k` |
| `AZURE_WEBAPP_NAME` | Name of the Azure Web App | `zavastore-dev-web-7x2k` |

> **Tip:** After deploying the Bicep templates you can retrieve the actual resource names from the Azure Portal or with `az resource list -g <resource-group> -o table`.
