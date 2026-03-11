# Container Deploy Workflow Quickstart

This folder includes a minimal workflow to build and deploy the app container to Azure App Service:
- deploy-webapp-container.yml

## 1) Configure GitHub repository variables

Add these in Settings -> Secrets and variables -> Actions -> Variables:

- ACR_NAME: Azure Container Registry name (for example, acr123abc)
- AZURE_RESOURCE_GROUP: Resource group containing the App Service
- AZURE_WEBAPP_NAME: Web App name created by your infra

## 2) Configure GitHub repository secret

Add this in Settings -> Secrets and variables -> Actions -> Secrets:

- AZURE_CLIENT_ID: Service principal (app registration) client ID
- AZURE_TENANT_ID: Microsoft Entra tenant ID
- AZURE_SUBSCRIPTION_ID: Azure subscription ID

Create a service principal and grant access to your resource group:

```bash
az ad sp create-for-rbac \
  --name "github-zava-deploy" \
  --role Contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP>
```

Then configure a federated credential on that app registration for your GitHub repo/branch (GitHub Actions OpenID Connect).

The workflow uses OIDC login and does not use AZURE_CREDENTIALS JSON.

## 3) Run deployment

- Push to main (changes under src), or
- Run the workflow manually from Actions -> Build and Deploy Container to App Service.
