# GitHub Actions CI/CD Setup

This workflow automatically builds the .NET application as a Docker container and deploys it to Azure App Service on each push to the `main` branch.

## Configuration

### Set GitHub Secrets

Configure these secrets in your repository settings (**Settings → Secrets and variables → Actions → Secrets**):

| Secret | Value | Description |
|--------|-------|-------------|
| `AZURE_CREDENTIALS` | JSON output from Azure CLI | Run: `az ad sp create-for-rbac --name zavastore-deploy --role contributor --scopes /subscriptions/<sub-id>/resourceGroups/rg-Zava-prod --sdk-auth` |

### Set GitHub Variables

Configure these variables in your repository settings (**Settings → Secrets and variables → Actions → Variables**):

| Variable | Value | Description |
|----------|-------|-------------|
| `AZURE_CONTAINER_REGISTRY_NAME` | `zavastorefrontdevacrdev` | ACR name (without `.azurecr.io`) |
| `AZURE_APP_SERVICE_NAME` | `app-zavastorefrontdev-dev` | Name of your App Service |

## How to Get ACR Credentials

```powershell
# Get registry login server
az acr show --name zavastorefrontdevacrdev --query loginServer -o tsv

# Get admin username and password
az acr credential show --name zavastorefrontdevacrdev --query "{username:username, password:passwords[0].value}"
```

## Workflow Behavior

- **Trigger**: Automatically runs on every push to `main` or manual trigger via GitHub UI
- **Build**: Builds Docker image with commit SHA as tag
- **Push**: Pushes image to ACR with tags `commit-sha` and `latest`
- **Deploy**: Updates App Service with new image
- **Restart**: Restarts App Service to pull and run the new container

## Manual Trigger

To manually trigger the workflow without pushing code:
1. Go to **Actions** tab in GitHub
2. Select **Build and Deploy to Azure**
3. Click **Run workflow**

## Monitoring

Check workflow runs and logs in the **Actions** tab of your repository.
