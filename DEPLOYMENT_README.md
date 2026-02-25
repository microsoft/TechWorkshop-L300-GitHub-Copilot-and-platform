# Deployment Quickstart (GitHub Actions)

This repo includes a workflow at `.github/workflows/deploy.yaml` to build a container image for the .NET app, push it to ACR, and deploy it to your existing Azure App Service.

## Required GitHub Secret

Create this repository **Secret** under Settings -> Secrets and variables -> Actions:

- `AZURE_CREDENTIALS`: Service principal JSON for `azure/login@v2`

Example structure:

```json
{
  "clientId": "<app-id>",
  "clientSecret": "<password>",
  "subscriptionId": "<subscription-id>",
  "tenantId": "<tenant-id>"
}
```

## Required GitHub Variables

Create these repository **Variables** under Settings -> Secrets and variables -> Actions:

- `ACR_NAME`: Azure Container Registry name (example: `myacrname`)
- `ACR_LOGIN_SERVER`: ACR login server (example: `myacrname.azurecr.io`)
- `AZURE_WEBAPP_NAME`: Existing App Service name created by your infra

## Triggers

The workflow runs on:

- push to `main`
- pull_request to `main`
- manual run (`workflow_dispatch`)

## PR behavior

- On `pull_request`: workflow validates container build only (no Azure login, no push, no deploy).
- On `push` to `main` and `workflow_dispatch`: workflow logs in to Azure, pushes to ACR, and deploys to App Service.

This avoids failures when PR secrets are unavailable (common for fork-based PRs).

_Workflow trigger note: documentation touch update._
