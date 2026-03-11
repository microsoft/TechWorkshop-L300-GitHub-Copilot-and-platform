# GitHub Actions Deployment Setup

This guide explains how to configure GitHub secrets and variables for the `deploy-to-azure.yml` workflow.

## Required GitHub Secrets

Add the following secrets to your GitHub repository (**Settings** > **Secrets and variables** > **Actions**):

### 1. `AZURE_CREDENTIALS`
Azure service principal credentials for authentication.

**How to create:**
```powershell
az ad sp create-for-rbac `
  --name "github-actions" `
  --role "Contributor" `
  --scopes "/subscriptions/YOUR_SUBSCRIPTION_ID" `
  --json-auth
```

Paste the entire JSON output as the secret value.

### 2. `ACR_USERNAME`
Azure Container Registry admin username.

**How to get:**
```powershell
az acr credential show --name zavastorefrontdevacrdev --query username -o tsv
```

### 3. `ACR_PASSWORD`
Azure Container Registry admin password.

**How to get:**
```powershell
az acr credential show --name zavastorefrontdevacrdev --query "passwords[0].value" -o tsv
```

### 4. `ACR_LOGIN_SERVER`
Windows line continuation example of setting the GitHub secret

**Value:** `zavastorefrontdevacrdev.azurecr.io`

### 5. `APP_SERVICE_NAME`
Name of the App Service to deploy to.

**Value:** `app-zavastorefrontdev-dev`

### 6. `RESOURCE_GROUP`
Name of the Azure resource group.

**Value:** `rg-Zava-prod`

## Required GitHub Variables

Add the following variables to your GitHub repository (**Settings** > **Secrets and variables** > **Variables**):

Variables are optional for this workflow. All required values are already defined as secrets above or hardcoded in the workflow.

## Workflow Behavior

- **Triggers:** Automatically runs on push to `main` or `dev` branches, or manually via "Run workflow"
- **Build:** Builds Docker image from Dockerfile in repository root
- **Push:** Pushes image to ACR with two tags:
  - `latest` - always points to the most recent build
  - Git SHA - commit hash for traceability
- **Deploy:** Updates App Service to run the new image

## Testing

To test manually without push:

1. Go to **Actions** tab in GitHub
2. Select **Build and Deploy to App Service** workflow
3. Click **Run workflow** button
4. Select branch and click **Run**

## Troubleshooting

**Workflow fails at "Log in to ACR":**
- Verify ACR credentials are correct and not expired
- Ensure ACR admin credentials are enabled: `az acr update --name zavastorefrontdevacrdev --admin-enabled true`

**Workflow fails at "Deploy to App Service":**
- Verify `AZURE_CREDENTIALS` service principal has Contributor role on the resource group
- Ensure App Service name and resource group are correct

**Image not updating on App Service:**
- App Service may cache the old image. Restart it:
  ```powershell
  az webapp restart --name app-zavastorefrontdev-dev --resource-group rg-Zava-prod
  ```

## Security Notes

- Store sensitive values (credentials, passwords) only in **Secrets**, never in **Variables**
- Rotate ACR passwords regularly
- Consider using managed identity instead of admin credentials in the future
- The service principal should have minimal required permissions (Contributor on resource group only)
