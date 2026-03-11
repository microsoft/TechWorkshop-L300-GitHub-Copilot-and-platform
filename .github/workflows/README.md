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

- AZURE_CREDENTIALS: Service principal JSON used by azure/login

Example creation command:

```bash
az ad sp create-for-rbac \
  --name "github-zava-deploy" \
  --role Contributor \
  --scopes /subscriptions/f991d37b-2e46-4fcd-b952-2601da6b0f96/resourceGroups/rg-TechWorkshop-L300-GitHub-Copilot-and-platform-dev \
  --sdk-auth
```

Copy the command output JSON into the AZURE_CREDENTIALS secret.

## 3) Run deployment

- Push to main (changes under src), or
- Run the workflow manually from Actions -> Build and Deploy Container to App Service.
