# Minimal GitHub Actions Workflow for .NET App Deployment

This workflow builds your .NET app, creates a Docker image, pushes it to Azure Container Registry (ACR), and deploys it to Azure App Service for Containers.

## Prerequisites
- Azure resources (ACR and App Service) must already exist (provisioned via your infra/ Bicep files).
- The following GitHub repository secrets must be set:
  - `AZURE_CLIENT_ID`: Azure service principal client ID
  - `AZURE_CLIENT_SECRET`: Azure service principal client secret
  - `AZURE_TENANT_ID`: Azure tenant ID
  - `AZURE_SUBSCRIPTION_ID`: Azure subscription ID
  - `REGISTRY_LOGIN_SERVER`: ACR login server (e.g., myregistry.azurecr.io)
  - `REGISTRY_USERNAME`: ACR username
  - `REGISTRY_PASSWORD`: ACR password
  - `WEBAPP_NAME`: Name of your Azure Web App
  - `RESOURCE_GROUP`: Resource group containing your Web App

## How to Configure Secrets
1. Go to your GitHub repository > Settings > Secrets and variables > Actions.
2. Add each secret above with the correct value.

## How to Configure Variables
- If you want to override the default image name or tag, you can add repository variables (same location as secrets).

---

- This workflow assumes your .NET app is in the `src/` folder and the Dockerfile is at `src/Dockerfile`.
- Adjust paths as needed for your project structure.
