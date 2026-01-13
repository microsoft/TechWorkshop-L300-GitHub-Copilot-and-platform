## GitHub Actions: Build and Deploy .NET App as Container to Azure App Service

This repo uses a minimal GitHub Actions workflow to build the .NET app in `src` as a container and deploy it to an Azure App Service defined in `infra`.

### Required GitHub Secrets

- `ACR_LOGIN_SERVER`: Azure Container Registry login server (e.g., `myregistry.azurecr.io`)
- `ACR_USERNAME`: Azure Container Registry username
- `ACR_PASSWORD`: Azure Container Registry password
- `AZURE_WEBAPP_PUBLISH_PROFILE`: Publish profile XML for your App Service (download from Azure Portal)

### Required GitHub Variables

- `IMAGE_NAME`: Name for your container image (e.g., `myapp`)
- `AZURE_WEBAPP_NAME`: Name of your Azure Web App

### How to Configure

1. Go to your GitHub repo → **Settings** → **Secrets and variables** → **Actions**.
2. Add the above secrets under the **Secrets** tab.
3. Add the above variables under the **Variables** tab.

The workflow will run on every push to the `main` branch.