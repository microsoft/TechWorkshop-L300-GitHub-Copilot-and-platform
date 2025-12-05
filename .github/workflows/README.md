# CI/CD Quickstart

## Configure GitHub Secret

Create one secret named `AZURE_CREDENTIALS` containing a service principal JSON:

```bash
az ad sp create-for-rbac --name "github-actions-sp" --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/rg-zavastore-dev-westus3 \
  --sdk-auth
```

Copy the entire JSON output and add it as a repository secret:
1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Name: `AZURE_CREDENTIALS`
4. Value: Paste the JSON output

## Usage

Push to `main` branch or manually trigger the workflow from the Actions tab.
