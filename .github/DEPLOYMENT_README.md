# GitHub Actions Deployment

This repository includes a GitHub Actions workflow to build and deploy the .NET application as a Docker container to Azure App Service.

## Configuration

### Secrets

Set the following secret in your GitHub repository (Settings > Secrets and variables > Actions):

- `AZURE_CREDENTIALS`: A JSON object containing your Azure service principal credentials. Generate one using `az ad sp create-for-rbac --name "GitHubActions" --role contributor --scopes /subscriptions/<subscription-id> --sdk-auth`. The JSON should look like:

```json
{
  "clientId": "...",
  "clientSecret": "...",
  "subscriptionId": "...",
  "tenantId": "..."
}
```

### Variables

Set the following variables in your GitHub repository (Settings > Secrets and variables > Actions > Variables):

- `AZURE_RESOURCE_GROUP`: The name of the Azure resource group (e.g., `rg-ZavaLabKimiya`)
- `AZURE_APP_SERVICE_NAME`: The name of the Azure App Service (e.g., `azwa2aaxibxirwbng`)
- `AZURE_CONTAINER_REGISTRY`: The name of the Azure Container Registry (e.g., `azacr2aaxibxirwbng`)

The workflow will trigger on pushes to the `main` branch, build the application, push the Docker image to ACR, and restart the App Service to deploy the new image.