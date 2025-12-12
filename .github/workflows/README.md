# GitHub Actions Workflow Configuration

This workflow builds the ZavaStorefront .NET application as a Docker container and deploys it to Azure App Service.

## Required Secrets

### `AZURE_CREDENTIALS`

Create a service principal with Contributor access to your resource group and AcrPush access to your container registry:

```bash
az ad sp create-for-rbac --name "github-actions-sp" \
  --role Contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP_NAME> \
  --sdk-auth
```

Copy the JSON output and add it as a repository secret named `AZURE_CREDENTIALS`.

Then grant the service principal permission to push images to ACR:

```bash
az role assignment create \
  --assignee <SERVICE_PRINCIPAL_APP_ID> \
  --role AcrPush \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP_NAME>/providers/Microsoft.ContainerRegistry/registries/<ACR_NAME>
```

## Required Variables

Configure these as repository variables in **Settings > Secrets and variables > Actions > Variables**:

| Variable   | Description                                      | Example              |
|------------|--------------------------------------------------|----------------------|
| `ACR_NAME` | Azure Container Registry name (without `.azurecr.io`) | `myacr`         |
| `APP_NAME` | Azure App Service name                           | `zavastore-dev`      |

## Triggering the Workflow

The workflow runs automatically on push to the `main` branch, or can be triggered manually via the **Actions** tab using "Run workflow".
