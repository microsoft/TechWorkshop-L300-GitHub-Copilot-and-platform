# GitHub Actions Deployment Setup

## Required GitHub Secrets

Add these secrets to your repository (Settings > Secrets and variables > Actions):

1. **`AZURE_CREDENTIALS`** — Service principal JSON for Azure login
   - Create via: `az ad sp create-for-rbac --name <app-name> --role Contributor --scope /subscriptions/<subscription-id>`
   - Paste the full JSON output as the secret value

2. **`AZURE_CONTAINER_REGISTRY_NAME`** — ACR name (without `.azurecr.io`)
   - Example: `zavastoredevacr`

3. **`AZURE_APP_SERVICE_NAME`** — Web App name
   - Example: `zavastoredev-web`

## Deployment Flow

The `.github/workflows/deploy-azure.yml` workflow:
1. Checks out code on `push` to `main` or `dev`
2. Logs into Azure using `AZURE_CREDENTIALS`
3. Builds and pushes Docker image to ACR via `az acr build`
4. Deploys the image to App Service via `azure/webapps-deploy`

## Local Provisioning (Optional)

To provision resources locally before pushing to GitHub:

```powershell
azd provision --preview
azd deploy
```

## Notes

- Image tag is based on Git commit SHA (`${{ github.sha }}`)
- Workflow runs on every push to `main` or `dev` branches
- Web App must have system-assigned managed identity with `AcrPull` role on ACR (configured via infra)
