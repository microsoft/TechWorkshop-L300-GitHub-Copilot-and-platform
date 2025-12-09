# GitHub Actions Deployment Setup

## Required GitHub Secrets

Configure these in your repository (`Settings > Secrets and variables > Actions`):

- **AZURE_CLIENT_ID** - Azure service principal application (client) ID
- **AZURE_TENANT_ID** - Azure AD tenant ID  
- **AZURE_SUBSCRIPTION_ID** - Azure subscription ID

## Quick Setup

### 1. Create Service Principal with Federated Identity

```bash
# Replace with your values
SUBSCRIPTION_ID="e8da3f1f-d5ec-4a6e-8cca-5cbef3e557db"
RESOURCE_GROUP="rg-zavastore-dev"
REPO="Zava-app-modernization/TechWorkshop-L300-GitHub-Copilot-and-platform"

# Create service principal
az ad sp create-for-rbac \
  --name "gh-zavastore-deploy" \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP \
  --json-auth

# Save the output - you'll need appId and tenant
```

### 2. Add Federated Credentials

```bash
# Replace <APP_ID> with appId from previous step
APP_ID="your-app-id"

# For main branch
az ad app federated-credential create \
  --id $APP_ID \
  --parameters "{
    \"name\": \"github-main\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:$REPO:ref:refs/heads/main\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }"

# For dev branch
az ad app federated-credential create \
  --id $APP_ID \
  --parameters "{
    \"name\": \"github-dev\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:$REPO:ref:refs/heads/dev\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }"
```

### 3. Add Secrets to GitHub

In your GitHub repository:
1. Go to `Settings > Secrets and variables > Actions`
2. Add three repository secrets:
   - `AZURE_CLIENT_ID` → appId from step 1
   - `AZURE_TENANT_ID` → tenant from step 1
   - `AZURE_SUBSCRIPTION_ID` → your subscription ID

### 4. Run the Workflow

The workflow triggers automatically on push to `main` or `dev`, or run manually:
- Go to `Actions > Build and Deploy > Run workflow`

## How It Works

1. **Retrieves resource names** from Bicep deployment outputs (no hardcoding needed)
2. **Builds container** using ACR cloud build (no local Docker required)
3. **Deploys to App Service** and restarts to pull the latest image

## Notes

- The workflow automatically discovers ACR and App Service names from your Bicep deployment
- Resource group is set to `rg-zavastore-dev` - update in workflow file if different
- Uses OIDC authentication (no passwords or keys stored)
