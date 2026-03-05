# CI/CD Quickstart

## Prerequisites

1. An Azure subscription with the infrastructure already provisioned (`azd up`).
2. A GitHub repo containing this code.
3. A Microsoft Entra **app registration** (or user-assigned managed identity with federated credentials) configured for [GitHub OIDC](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect).

## GitHub Secrets (Settings → Secrets and variables → Actions → Secrets)

| Secret | Description |
|---|---|
| `AZURE_CLIENT_ID` | App registration (service principal) client/application ID |
| `AZURE_TENANT_ID` | Microsoft Entra tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |

> The workflow uses OIDC federated credentials — no client secret is needed.

## GitHub Variables (Settings → Secrets and variables → Actions → Variables)

| Variable | Description | How to find |
|---|---|---|
| `AZURE_RESOURCE_GROUP` | Resource group containing the Container App | Azure Portal or `az group list` |
| `AZURE_CONTAINER_REGISTRY_NAME` | ACR short name (e.g. `crzavaXXXXX`) | `az acr list -o table` |
| `AZURE_CONTAINER_REGISTRY_LOGIN_SERVER` | ACR login server (e.g. `crzavaXXXXX.azurecr.io`) | `az acr list -o table` |
| `AZURE_CONTAINER_APP_NAME` | Container App name (e.g. `ca-zavaXXXXX`) | `az containerapp list -o table` |

> Tip: After running `azd up`, all of these values are printed as outputs and stored in `azd env get-values`.

## Required Azure Permissions

The service principal needs:
- **AcrPush** on the Container Registry (to build & push images).
- **Contributor** (or **Azure ContainerApps Session Executor**) on the resource group (to update the Container App).

## Trigger

The workflow runs on every push to `main` and can be triggered manually via **Actions → Build and Deploy → Run workflow**.
