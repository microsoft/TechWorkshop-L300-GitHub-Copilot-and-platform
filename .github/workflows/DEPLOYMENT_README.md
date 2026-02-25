# GitHub Actions Deployment Setup

## Required Secret

| Secret | Description |
|---|---|
| `AZURE_CREDENTIALS` | Service principal JSON for Azure login |

Generate with:
```bash
az ad sp create-for-rbac \
  --name "zava-storefront-gh-actions" \
  --role Contributor \
  --scopes /subscriptions/<subscription-id>/resourceGroups/<resource-group> \
  --sdk-auth
```
Copy the full JSON output into a GitHub repository secret named `AZURE_CREDENTIALS`.

## Required Variables

| Variable | Example Value |
|---|---|
| `AZURE_RESOURCE_GROUP` | `demo_rg` |
| `AZURE_ACR_NAME` | `acrpqfr5bifzhme2` |
| `AZURE_WEBAPP_NAME` | `app-zava-dev-pqfr5bifzhme2` |

Add these under **Settings → Secrets and variables → Actions → Variables**.

## Notes

- The workflow uses ACR Tasks (`az acr build`) — no Docker required on the runner.
- The Web App uses its **system-assigned managed identity** with the `AcrPull` role on ACR — no registry credentials needed in the workflow.
- Each deployment tags the image with the Git commit SHA for traceability.
