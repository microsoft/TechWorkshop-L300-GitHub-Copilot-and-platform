# ZavaStorefront – Azure Infrastructure

Modular Bicep + AZD infrastructure for the ZavaStorefront web application (dev environment).

## Architecture

| Resource | SKU / Kind | Purpose |
|---|---|---|
| Log Analytics workspace | PerGB2018 | Central log store for App Insights |
| Application Insights | web | Telemetry & monitoring |
| Container Registry | Basic | Docker image storage (RBAC-only pulls) |
| App Service Plan | B1 Linux | Compute for the Web App |
| Web App | Linux container | Hosts the .NET container image |
| AI Foundry Hub | Dev | AI model governance |
| AI Foundry Project | Dev | GPT-4 & Phi-4 model endpoints |
| RBAC: AcrPull | Built-in | Web App managed identity → ACR |

All resources are deployed to **westus3** in a single resource group.

---

## Prerequisites

| Tool | Install |
|---|---|
| Azure CLI | `winget install Microsoft.AzureCLI` |
| Azure Developer CLI (AZD) | `winget install Microsoft.Azd` |
| GitHub CLI (optional) | `winget install GitHub.cli` |

No local Docker installation is required. Container builds run cloud-side via `az acr build`.

---

## First-time provisioning

```bash
# 1. Authenticate
az login
azd auth login

# 2. Initialise the AZD environment (run from repo root)
azd env new dev

# 3. Provision all Azure resources (~5-10 min)
azd provision

# 4. Build and push the container image to ACR (cloud-side build)
ACR_NAME=$(azd env get-values | grep acrName | cut -d= -f2 | tr -d '"')
az acr build \
  --registry "$ACR_NAME" \
  --image zava-storefront:latest \
  --file ./Dockerfile \
  ./src

# 5. Update the image reference and deploy the Web App
azd env set containerImage "${ACR_NAME}.azurecr.io/zava-storefront:latest"
azd deploy
```

After completion, `azd` prints the Web App URL. Open it in a browser to verify.

---

## Incremental deployments

To deploy code changes only (no infra changes):

```bash
az acr build --registry "$ACR_NAME" --image zava-storefront:$(git rev-parse --short HEAD) --file ./Dockerfile ./src
azd env set containerImage "${ACR_NAME}.azurecr.io/zava-storefront:$(git rev-parse --short HEAD)"
azd deploy
```

To apply infrastructure changes only:

```bash
azd provision
```

---

## CI/CD via GitHub Actions

The workflow `.github/workflows/deploy.yml` triggers automatically on pushes to `dev` and `main`.

### Required repository secrets

| Secret | Description |
|---|---|
| `AZURE_CLIENT_ID` | Client ID of a federated service principal or managed identity |
| `AZURE_TENANT_ID` | Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |

### Required repository variables

| Variable | Example value |
|---|---|
| `AZURE_ENV_NAME` | `dev` |

Use OIDC federated credentials (no long-lived secrets). See [Azure/login OIDC docs](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect).

---

## Security notes

- ACR `adminUserEnabled` is **false** — all image pulls use the Web App system-assigned managed identity with the `AcrPull` role.
- No registry passwords are stored in App Service app settings.
- App Insights uses the **connection string** (not the deprecated instrumentation key alone).
- HTTPS-only is enforced on the Web App. TLS 1.2 minimum is configured.

---

## Cost estimate (dev)

| Resource | ~Monthly cost |
|---|---|
| App Service Plan B1 | ~$13 USD |
| Container Registry Basic | ~$5 USD |
| Log Analytics (first 5 GB/month free) | ~$0-2 USD |
| Application Insights (first 5 GB/month free) | ~$0-2 USD |
| AI Foundry (dev tier) | Pay-per-use |

---

## Foundry model notes

- Both **GPT-4** and **Phi-4** are deployed in `westus3` where they are available.
- Initial capacity is set to `1` TPM (dev minimum). Increase via the AI Foundry portal if needed.
- To get the project endpoint after provisioning: `azd env get-values | grep aiFoundryEndpoint`
