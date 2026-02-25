# GitHub Actions Deployment Setup

## Authentication (OIDC / Federated Identity)

This workflow uses GitHub OIDC federation with Azure (`azure/login@v2`) and does **not** require `AZURE_CREDENTIALS`.

Create a service principal and grant access to your resource group:

```bash
az ad sp create-for-rbac \
  --name "zava-storefront-gh-actions" \
  --role Contributor \
  --scopes /subscriptions/<subscription-id>/resourceGroups/<resource-group>
```

Create a federated credential on the app registration:

```bash
az ad app federated-credential create \
  --id <app-object-id> \
  --parameters '{
    "name": "github-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:<owner>/<repo>:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

Use `repo:<owner>/<repo>:pull_request` as `subject` if you also want PR runs to authenticate.

Current workflow behavior: PRs run build validation only; Azure deploy runs on `push` to `main` and `workflow_dispatch`.

## Required Variables

| Variable | Example Value |
|---|---|
| `AZURE_CLIENT_ID` | `<service-principal-app-id>` |
| `AZURE_TENANT_ID` | `<tenant-id>` |
| `AZURE_SUBSCRIPTION_ID` | `85216ba0-ec34-4bc3-aabf-b5117104de98` |
| `AZURE_RESOURCE_GROUP` | `demo_rg` |
| `AZURE_ACR_NAME` | `acrpqfr5bifzhme2` |
| `AZURE_WEBAPP_NAME` | `app-zava-dev-pqfr5bifzhme2` |

Add these under **Settings → Secrets and variables → Actions → Variables**.

## Notes

- The workflow uses ACR Tasks (`az acr build`) — no Docker required on the runner.
- The Web App uses its **system-assigned managed identity** with the `AcrPull` role on ACR — no registry credentials needed in the workflow.
- Each deployment tags the image with the Git commit SHA for traceability.
- OIDC deploy auth requires a federated credential subject matching `repo:<owner>/<repo>:ref:refs/heads/main`.
