# CI/CD Quickstart

## 1. Configure GitHub Secret

Create a service principal and add it as a secret:

```bash
az ad sp create-for-rbac --name "github-actions-zavastore" \
  --role contributor \
  --scopes /subscriptions/<YOUR-SUBSCRIPTION-ID>/resourceGroups/rg-zavastore-dev-westus3 \
  --sdk-auth
```

Add the JSON output as a repository secret:

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Name: `AZURE_CREDENTIALS`
4. Value: Paste the entire JSON output

## 2. Configure GitHub Variables

Add these repository variables (Settings → Secrets and variables → Actions → Variables):

| Variable | Value |
|----------|-------|
| `ACR_NAME` | `zavastoredevacrwadq` |
| `RESOURCE_GROUP` | `rg-zavastore-dev-westus3` |
| `APP_NAME` | `zavastore-dev-web` |

## Usage

- **Push to `main`** (changes in `src/` or `infra/Dockerfile`): Builds and deploys
- **Pull request**: Builds only (validates the image builds successfully)
- **Manual**: Trigger from Actions tab
