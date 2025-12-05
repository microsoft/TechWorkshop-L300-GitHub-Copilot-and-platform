# GitHub Actions Deployment Setup

## Prerequisites

- Azure infrastructure deployed via `azd up` (creates ACR, App Service, etc.)
- GitHub repository with OIDC authentication configured

## Required Variables

Configure these in **Settings → Secrets and variables → Actions → Variables**:

| Variable | Description | Example Value |
|----------|-------------|---------------|
| `AZURE_CLIENT_ID` | Service principal client ID | `89ff6254-366b-...` |
| `AZURE_TENANT_ID` | Azure AD tenant ID | `8d535122-53a2-...` |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID | `9ecaa2a8-2c4d-...` |
| `ACR_NAME` | Container Registry name | `crzavastoredev3il6kg7r` |
| `WEBAPP_NAME` | App Service name | `app-zavastore-dev-3il6kg7r` |
| `RESOURCE_GROUP` | Resource group name | `TechWorkshop` |

> **Tip:** Run `azd pipeline config` to set up Azure credentials automatically.

Get resource values from `.azure/dev/.env` after running `azd provision`.

## Usage

Push to `main` to trigger deployment, or run manually via **Actions → Deploy to Azure → Run workflow**.
