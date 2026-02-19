# GitHub Actions: Build and Deploy to Azure Web App (Container)

This repository includes a minimal GitHub Actions workflow to build your .NET app as a container and deploy it to an Azure App Service (Linux, container) defined in your `infra` folder.

## Required GitHub Secrets
Set these secrets in your repository (Settings > Secrets and variables > Actions > New repository secret):

- `AZURE_CONTAINER_REGISTRY` — The login server name of your Azure Container Registry (e.g., `myregistry.azurecr.io`)
- `AZURE_CONTAINER_REGISTRY_USERNAME` — Username for your ACR (use `az acr credential show` to get it)
- `AZURE_CONTAINER_REGISTRY_PASSWORD` — Password for your ACR (use `az acr credential show` to get it)
- `AZURE_WEBAPP_NAME` — Name of your Azure Web App (as defined in your Bicep/infra)

## How it works
- On push to `main`, the workflow:
  1. Builds your .NET app as a Docker container
  2. Pushes the image to your Azure Container Registry
  3. Deploys the image to your Azure Web App (Linux, container)

No other scripts or files are required. For more details, see the workflow file in `.github/workflows/deploy-appservice-container.yml`.
