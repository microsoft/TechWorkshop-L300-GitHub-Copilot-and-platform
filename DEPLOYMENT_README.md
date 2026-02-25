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

- On `pull_request`: workflow performs full login, build, push to ACR, and App Service deploy.
- On `push` to `main` and `workflow_dispatch`: workflow also performs full login, build, push, and deploy.

Note: PRs from forks may fail because repository secrets are not exposed to untrusted fork workflows.

_Workflow trigger note: documentation touch update._
