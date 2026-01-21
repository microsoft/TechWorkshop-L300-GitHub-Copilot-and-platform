# Minimal GitHub Actions Workflow for .NET App Deployment

This workflow builds and deploys the ZavaStorefront .NET app as a container to Azure App Service using GitHub Actions.

## Prerequisites
- Azure App Service and Azure Container Registry (ACR) are already provisioned (see infra/).
- The app is containerized and the Dockerfile is in the `src` folder.

## Required GitHub Secrets
Set these secrets in your repository (Settings > Secrets and variables > Actions > New repository secret):

- `AZURE_CLIENT_ID`: Azure service principal client ID
- `AZURE_TENANT_ID`: Azure tenant ID
- `AZURE_CLIENT_SECRET`: Azure service principal client secret
- `AZURE_SUBSCRIPTION_ID`: Azure subscription ID

## Required GitHub Variables
Set these variables in your repository (Settings > Secrets and variables > Actions > New repository variable):

- `AZURE_WEBAPP_NAME`: Name of your Azure App Service
- `AZURE_CONTAINER_REGISTRY`: Login server of your ACR (e.g., `acrmxe36chfff5wk.azurecr.io`)
- `CONTAINER_IMAGE_NAME`: Name for the image (e.g., `zavastorefront`)

## Usage
This workflow will automatically run on push to the `main` branch. It will:
1. Log in to Azure
2. Build and push the Docker image to ACR, always tagging it as `latest`
3. Deploy the `latest` image to Azure App Service

**Note:** The Azure Web App is configured to use the `latest` tag from your ACR. The workflow always overwrites the `latest` tag to ensure deployments match the web app configuration.

No additional scripts or files are required.
