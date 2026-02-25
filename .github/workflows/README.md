# Container deploy workflow quickstart

This folder contains a minimal GitHub Actions workflow that:

- Builds the `src` .NET app as a container image using `az acr build`
- Pushes the image to your existing Azure Container Registry
- Updates your existing Azure Web App for Containers to the new image tag

## 1) Configure GitHub repository secrets

Add these repository secrets:

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

These are used by `azure/login@v2` with OIDC federation.

## 2) Configure GitHub repository variables

Add these repository variables:

- `ACR_NAME` (example: `azacrym7lisaqm2ho2`)
- `WEBAPP_NAME` (example: `azwebym7lisaqm2ho2`)
- `AZURE_RESOURCE_GROUP` (example: `rg-dev`)

## 3) Run

- Push to `main`, or
- Run workflow manually from the Actions tab (`workflow_dispatch`)
