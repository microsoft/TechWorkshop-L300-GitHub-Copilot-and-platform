# GitHub Actions Deployment Setup

This document explains how to configure GitHub secrets and variables for the automated deployment workflow.

## Prerequisites

- Azure infrastructure already deployed (App Service, Container Registry)
- Azure CLI installed locally
- Contributor access to your Azure subscription

## Required GitHub Secrets

### ACR_LOGIN_SERVER

The full login server URL for your Azure Container Registry.

**To create:**

1. In GitHub, go to: **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

2. Name: `ACR_LOGIN_SERVER`

3. Value: Your ACR login server (e.g., `myregistry.azurecr.io`)

### ACR_USERNAME

The username for your Azure Container Registry.

**To create:**

1. Get your ACR username from Azure Portal or run:

```bash
az acr credential show --name {your-acr-name} --query username -o tsv
```

2. In GitHub, go to: **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

3. Name: `ACR_USERNAME`

4. Value: Your ACR username

### ACR_PASSWORD

The password for your Azure Container Registry.

**To create:**

1. Get your ACR password from Azure Portal or run:

```bash
az acr credential show --name {your-acr-name} --query "passwords[0].value" -o tsv
```

2. In GitHub, go to: **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

3. Name: `ACR_PASSWORD`

4. Value: Your ACR password

## Required GitHub Variables

### IMAGE_NAME

The name of the Docker image to use.

**To create:**

1. In GitHub, go to: **Settings** → **Secrets and variables** → **Actions** → **Variables** tab → **New repository variable**

2. Name: `IMAGE_NAME`

3. Value: Your image name (e.g., `simplestore`)

### AZURE_APP_SERVICE_NAME

The name of your Azure App Service.

**To create:**

1. In GitHub, go to: **Settings** → **Secrets and variables** → **Actions** → **Variables** tab → **New repository variable**

2. Name: `AZURE_APP_SERVICE_NAME`

3. Value: Your App Service name (e.g., `my-app-service`)

## Workflow Trigger

The workflow runs automatically on:

- Push to `main` branch
- Pull request to `main` branch
- Manual trigger via **Actions** → **Workflow name** → **Run workflow**

## Troubleshooting

**Authentication fails:** Verify ACR credentials are correct and have not been regenerated

**ACR build fails:** Check that ACR admin user is enabled in Azure Portal

**Deployment fails:** Ensure App Service is configured for Linux containers and has proper permissions to pull from ACR
