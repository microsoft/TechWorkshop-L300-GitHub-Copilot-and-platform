# GitHub Actions quickstart (App Service container deploy)

This repo includes `.github/workflows/deploy-appservice-container.yml` to build and deploy the `src` Docker image to an existing Azure App Service.

## 1) Configure GitHub Secrets

Create these repository secrets:

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

These are used by `azure/login` with OpenID Connect (OIDC).

## 2) Configure GitHub Variables

Create these repository variables:

- `AZURE_WEBAPP_NAME` (App Service name)
- `AZURE_RESOURCE_GROUP` (resource group containing the app)
- `ACR_NAME` (Azure Container Registry name, without `.azurecr.io`)
- `CONTAINER_IMAGE_NAME` (optional, defaults to `zavastorefront`)

## 3) Run

Push to `main` or run the workflow manually from the Actions tab.
