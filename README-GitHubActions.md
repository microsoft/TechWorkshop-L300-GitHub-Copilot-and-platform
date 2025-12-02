# GitHub Actions: Azure .NET Container Quickstart

This workflow builds your .NET app, packages it as a Docker container, pushes it to Azure Container Registry, and deploys it to Azure App Service (Container).

## Required GitHub Secrets

You must create the following secrets in your GitHub repository:

- `ACR_LOGIN_SERVER`: Your Azure Container Registry login server (e.g., `zavaacrdev20251202.azurecr.io`)
- `ACR_USERNAME`: ACR username (use a service principal or admin user)
- `ACR_PASSWORD`: ACR password
- `AZURE_WEBAPP_NAME`: Name of your Azure App Service (Container)
- `AZURE_WEBAPP_PUBLISH_PROFILE`: Publish profile XML for your web app (download from Azure Portal)

### How to Create GitHub Secrets
1. Go to your repository on GitHub.
2. Click on **Settings** (top menu).
3. In the left sidebar, click **Secrets and variables** > **Actions**.
4. Click the **New repository secret** button.
5. Enter the name (e.g., `ACR_LOGIN_SERVER`) and the value for each secret listed above.
6. Click **Add secret**.
7. Repeat for each required secret.

#### How to Get the Publish Profile
1. In the [Azure Portal](https://portal.azure.com), navigate to your App Service.
2. In the left menu, click **Get publish profile**.
3. Download the `.PublishSettings` file and open it in a text editor.
4. Copy the entire XML content and use it as the value for the `AZURE_WEBAPP_PUBLISH_PROFILE` secret.

## Optional GitHub Variables
You may use repository variables for environment-specific values, but this workflow only requires the secrets above.

## Usage
1. Add the workflow file to `.github/workflows/azure-dotnet-container.yml`.
2. Configure the required secrets in your repository (see above).
3. Push to the `main` branch to trigger build and deployment.

No other scripts or files are required for this quickstart.
