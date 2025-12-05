# GitHub Actions Deployment Setup

This repository contains a GitHub Actions workflow that automatically builds and deploys your .NET application as a container to Azure App Service.

## Prerequisites

Before the workflow can run successfully, you need to configure the following GitHub secrets and variables.

## Required GitHub Secrets

### 1. AZURE_CREDENTIALS

Create an Azure Service Principal with contributor access to your resource group:

```bash
az ad sp create-for-rbac --name "github-actions-sp" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group-name} \
  --json-auth
```

Copy the entire JSON output and add it as the `AZURE_CREDENTIALS` secret in GitHub.

## Required GitHub Variables

Go to your repository → Settings → Secrets and variables → Actions → Variables tab and add:

### 1. AZURE_CONTAINER_REGISTRY
The name of your Azure Container Registry (without .azurecr.io suffix)
- Example: `acrvdvbhaauvps34zavastoreenv001`

### 2. AZURE_APP_SERVICE_NAME
The name of your Azure App Service
- Example: `app-zavastore-env001-vdvbhaauvps34`

### 3. AZURE_RESOURCE_GROUP
The name of your Azure Resource Group
- Example: `rg-zavastore-env001-swedencentral`

## Finding Your Resource Names

You can find these values by running:

```bash
# List your resource groups
az group list --query "[].name" --output table

# List App Services in your resource group
az webapp list --resource-group <your-rg> --query "[].name" --output table

# List Container Registries in your resource group
az acr list --resource-group <your-rg> --query "[].name" --output table
```

Or check your azd environment values:

```bash
azd env get-values
```

## Workflow Behavior

- **Triggers**: Pushes to `main` or `dev` branches, pull requests to `main`, and manual dispatch
- **Build**: Uses Azure Container Registry build (no local Docker required)
- **Deploy**: Updates App Service with the new container image
- **Tagging**: Images are tagged with both the git SHA and `latest`

## Testing the Workflow

1. Push changes to the `dev` or `main` branch
2. Check the Actions tab in your GitHub repository
3. Monitor the workflow execution
4. Visit your App Service URL to verify the deployment

## Troubleshooting

### Common Issues

1. **Authentication failed**: Verify `AZURE_CREDENTIALS` secret is correctly formatted JSON
2. **Resource not found**: Double-check all variable names match your actual Azure resources
3. **Permission denied**: Ensure the service principal has contributor access to the resource group
4. **Container registry login failed**: Verify the ACR name in variables matches your actual registry

### Debugging Tips

- Enable debug logging by adding `ACTIONS_STEP_DEBUG: true` to repository secrets
- Check App Service logs in Azure Portal
- Verify container image was pushed to ACR successfully