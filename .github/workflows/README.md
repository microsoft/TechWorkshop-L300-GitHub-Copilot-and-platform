# Quickstart: App Service container deploy workflow

This folder includes a minimal workflow to build the `src` Docker image and deploy it to your existing Azure App Service.

## 1) Configure GitHub Secrets

In your repository, go to **Settings > Secrets and variables > Actions > Secrets** and add:

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

These values should come from the Microsoft Entra application/service principal that has a federated credential for this repository.

## 2) Configure GitHub Variables

In **Settings > Secrets and variables > Actions > Variables**, add:

- `AZURE_RESOURCE_GROUP` (example: `rg-<your-environment-name>`)
- `AZURE_WEB_APP_NAME` (from infra output `AZURE_WEB_APP_NAME`)
- `ACR_NAME` (from infra output `ACR_NAME`)

## 3) Run the workflow

Use the workflow at `.github/workflows/deploy-appservice-container.yml`.

- It runs on pushes to `main` when `src/**` changes.
- You can also run it manually with **Run workflow**.