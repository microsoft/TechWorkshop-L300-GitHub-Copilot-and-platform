# GitHub Actions Deployment Setup

This workflow builds the .NET application as a Docker container in Azure Container Registry and deploys it to Azure App Service using OIDC (OpenID Connect) for secure, secretless authentication.

## Prerequisites

- Azure infrastructure already provisioned (ACR and App Service)
- GitHub repository with appropriate permissions

## Configuration (Already Done)

A service principal with federated credentials has been created:

- **App ID:** `75f88d8c-7555-4ebb-9129-6e9c90fbad41`
- **Federated credentials:** Configured for `main` and `dev` branches
- **Role:** Contributor on `rg-test` resource group

## Configure GitHub Variables

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** → **Variables** tab.

Create the following **Repository Variables**:

| Name | Value |
|------|-------|
| `AZURE_CLIENT_ID` | `75f88d8c-7555-4ebb-9129-6e9c90fbad41` |
| `AZURE_TENANT_ID` | `16b3c013-d300-468d-ac64-7eda0820b6d3` |
| `AZURE_SUBSCRIPTION_ID` | `5721c728-2e79-4d41-a67f-e3b2f5852c0a` |
| `RESOURCE_GROUP_NAME` | `rg-test` |
| `AZURE_CONTAINER_REGISTRY_NAME` | `acrzavastorefrontdevsk4lt2o3ywuka` |
| `AZURE_APP_SERVICE_NAME` | `app-zavastorefront-dev-sk4lt2o3ywuka` |

## Workflow Triggers

The workflow runs automatically on:
- Push to `main` or `dev` branch (changes in `src/` folder)
- Manual trigger via GitHub Actions UI (workflow_dispatch)

## Troubleshooting

**OIDC Authentication Failed**
- Verify all `AZURE_*` variables are set correctly
- Ensure the repository name matches the federated credential subject

**ACR Build Failed**
- Check that `ACR_NAME` variable is correct (name only, not URL)

**App Service Deployment Failed**
- Confirm `APP_SERVICE_NAME` and `RESOURCE_GROUP_NAME` are correct
