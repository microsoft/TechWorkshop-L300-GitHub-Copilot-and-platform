# GitHub Actions Deployment Setup

## Prerequisites

- Azure infrastructure deployed via `azd up` (creates ACR, App Service, etc.)
- GitHub repository with OIDC authentication configured

## Required Secrets

Configure these in **Settings → Secrets and variables → Actions → Secrets**:

| Secret | Description |
|--------|-------------|
| `AZURE_CLIENT_ID` | Service principal/app registration client ID |
| `AZURE_TENANT_ID` | Azure AD tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID |

> **Tip:** Run `azd pipeline config` to set these up automatically.

## Required Variables

Configure these in **Settings → Secrets and variables → Actions → Variables**:

| Variable | Example Value |
|----------|---------------|
| `ACR_NAME` | `crzavastoredev3il6kg7r` |
| `WEBAPP_NAME` | `app-zavastore-dev-3il6kg7r` |
| `RESOURCE_GROUP` | `TechWorkshop` |

Get these values from `.azure/dev/.env` after running `azd provision`.

## Usage

Push to `main` to trigger deployment, or run manually via **Actions → Deploy to Azure → Run workflow**.
