# App Service Container Deploy Quickstart

This repo includes a minimal workflow at `.github/workflows/appservice-container-deploy.yml` that:
- Builds a container image from `src/Dockerfile`
- Pushes it to your Azure Container Registry (ACR)
- Deploys that image to your Azure App Service

## Configure Repository Variables

Set these in GitHub: **Settings -> Secrets and variables -> Actions -> Variables**

- `AZURE_WEBAPP_NAME`: Your App Service name (for example, `azappabc123`)
- `ACR_NAME`: Your ACR name only (for example, `myregistry`)

## Configure Repository Secrets

Set these in GitHub: **Settings -> Secrets and variables -> Actions -> Secrets**

- `AZURE_CLIENT_ID`: Service principal application (client) ID
- `AZURE_TENANT_ID`: Microsoft Entra tenant ID
- `AZURE_SUBSCRIPTION_ID`: Azure subscription ID

This workflow uses OpenID Connect (OIDC) with `azure/login@v2`, so no `AZURE_CLIENT_SECRET` is required.

## OIDC Setup (Best Practice)

Create a federated credential on the Microsoft Entra application used by `AZURE_CLIENT_ID` with:
- Issuer: `https://token.actions.githubusercontent.com`
- Subject (branch deploy): `repo:jsh-free-org2/TechWorkshop-L300-GitHub-Copilot-and-platform:ref:refs/heads/main`
- Subject (manual run): same as above when run from `main`
- Audience: `api://AzureADTokenExchange`

## Run

- Push to `main`, or
- Run the workflow manually from the Actions tab (`workflow_dispatch`)
