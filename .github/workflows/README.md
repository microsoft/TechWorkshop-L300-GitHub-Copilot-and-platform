# App Service Container Deployment Workflow (Quickstart)

This repo includes a minimal workflow at `.github/workflows/deploy-appservice-container.yml` that:
1. Builds the container image from `src/Dockerfile`
2. Pushes it to Azure Container Registry (ACR)
3. Updates the existing Azure App Service container image

## 1) Configure GitHub Secrets

Add these repository secrets:
az ad sp create-for-rbac --name "github-actions-sp" \
  --role contributor \
  --scopes /subscriptions/9e94cd08-66a0-49c6-b138-ef9aebb58b7c/resourceGroups/techworkshop-l300-ai-agents
 \
  --json-auth


These are used by `azure/login@v2` with OpenID Connect (OIDC).

## 2) Configure GitHub Variables

Add these repository variables:
- `AZURE_RESOURCE_GROUP` (resource group containing your App Service and ACR)
- `AZURE_WEBAPP_NAME` (the App Service name from your infra deployment)
- `AZURE_ACR_NAME` (the ACR name from your infra deployment)
- `IMAGE_NAME` (optional, default is `zavastorefront`)

## 3) Required Azure Role Assignments

Grant the service principal (`AZURE_CLIENT_ID`) at minimum:
- `AcrPush` on the ACR
- `Contributor` on the App Service resource (or resource group)

## 4) Run the workflow

Trigger it manually via **Actions** (`workflow_dispatch`) or push to `main` with changes under `src/`.
