# GitHub Actions Quickstart (App Service Container Deploy)

This repository includes [deploy-appservice-container.yml](deploy-appservice-container.yml), which:
- Builds a Docker image for this .NET app.
- Pushes the image to your existing Azure Container Registry (ACR).
- Updates your existing App Service to use the new image tag.

## 1) Configure GitHub Secrets

Add these repository secrets:
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

These are used by `azure/login` with OpenID Connect (OIDC).

## 2) Configure GitHub Variables

Add these repository variables:
- `AZURE_CONTAINER_REGISTRY_NAME` (ACR name only, without `.azurecr.io`)
- `AZURE_APP_SERVICE_NAME` (existing Azure App Service name)

Optional variable:
- `CONTAINER_IMAGE_NAME` (defaults to `zavastorefront`)

How to configure secrets and variables:
- Go to your GitHub repository.
- Click **Settings** -> **Secrets and variables** -> **Actions**.
- Add `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID` under the **Secrets** tab.
- Add `AZURE_CONTAINER_REGISTRY_NAME`, `AZURE_APP_SERVICE_NAME`, and optional `CONTAINER_IMAGE_NAME` under the **Variables** tab.

## 3) Create Federated Credential for OIDC

In Microsoft Entra ID for the app registration/service principal behind `AZURE_CLIENT_ID`, add a federated credential with:
- Issuer: `https://token.actions.githubusercontent.com`
- Subject: `repo:<OWNER>/<REPO>:ref:refs/heads/main`
- Audience: `api://AzureADTokenExchange`

Grant that identity access in Azure (minimum):
- `AcrPush` on your ACR
- `Contributor` on the App Service resource group (or equivalent scoped permissions to update the App Service config)

## 4) Run

Push to `main` or run the workflow manually from the Actions tab.
