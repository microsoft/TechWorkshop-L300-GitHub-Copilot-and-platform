# Workflow Setup

`deploy.yml` builds the container image via ACR Tasks and deploys it to App Service on every push to `main`.
It uses OpenID Connect (OIDC) — no long-lived credentials are stored.

## Azure setup status

The app registration, service principal, Contributor role assignment, and federated credential have
already been provisioned:

| Item | Value |
|---|---|
| App registration | `github-actions-zava-kblee` |
| Application (client) ID | `156ce8c9-b630-49dd-9f65-a7c2bd5e1c64` |
| Object ID (app) | `d7a2c13c-5edc-4e14-a868-0a6400615f56` |
| Service principal object ID | `a9763dc2-0781-4dc6-8cae-48756a5ee3ff` |
| Tenant ID | `16b3c013-d300-468d-ac64-7eda0820b6d3` |
| Subscription ID | `4a65717c-1f05-44d6-9b4b-ff6faf5e0fa8` |
| Resource group | `rg-KeonTest` |
| Role | Contributor (scoped to `rg-KeonTest`) |
| Federated credential | `github-main` (subject must be updated — see below) |

### Fix the federated credential subject

The credential was created with a placeholder subject. Replace `ORG/REPO` with your actual
GitHub org and repository name, then run:

```bash
az ad app federated-credential delete \
  --id d7a2c13c-5edc-4e14-a868-0a6400615f56 \
  --federated-credential-id 59dd68a1-4656-4669-a58d-24e24c395e9c

az ad app federated-credential create \
  --id d7a2c13c-5edc-4e14-a868-0a6400615f56 \
  --parameters '{
    "name": "github-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:ORG/REPO:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### Grant AcrPush role (required to push images)

```bash
ACR_ID=$(az acr show --name <ACR_NAME> --query id -o tsv)
az role assignment create \
  --assignee 156ce8c9-b630-49dd-9f65-a7c2bd5e1c64 \
  --role AcrPush \
  --scope $ACR_ID
```

## GitHub Secrets

Navigate to **Settings → Secrets and variables → Actions → Secrets** and add:

| Secret | Value |
|---|---|
| `AZURE_CLIENT_ID` | `156ce8c9-b630-49dd-9f65-a7c2bd5e1c64` |
| `AZURE_TENANT_ID` | `16b3c013-d300-468d-ac64-7eda0820b6d3` |
| `AZURE_SUBSCRIPTION_ID` | `4a65717c-1f05-44d6-9b4b-ff6faf5e0fa8` |

## GitHub Variables

Navigate to **Settings → Secrets and variables → Actions → Variables** and add:

| Variable | Example value | How to find it |
|---|---|---|
| `ACR_NAME` | `acrzava12ab34cd` | `az acr list -o table` or Bicep output `acrName` |
| `APP_SERVICE_NAME` | `app-zava-dev-a1b2c3` | `az webapp list -o table` or Bicep output `appName` |
| `AZURE_RESOURCE_GROUP` | `rg-KeonTest` | Already provisioned |

> **Tip:** After running `azd provision`, get ACR and App Service names in one command:
> ```bash
> azd env get-values
> ```
> Look for `AZURE_CONTAINER_REGISTRY_NAME` and `SERVICE_WEB_NAME`.
