# ZavaStorefront Azure Infrastructure

This document describes the Azure infrastructure for the ZavaStorefront web application.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Resource Group: rg-zavastore-dev-westus3                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐       │
│  │  Azure          │     │  App Service    │     │  Web App for    │       │
│  │  Container      │────▶│  Plan (Linux)   │────▶│  Containers     │       │
│  │  Registry       │     │  B1 SKU         │     │  (Managed ID)   │       │
│  │  (Basic SKU)    │     └─────────────────┘     └────────┬────────┘       │
│  └─────────────────┘                                      │                │
│          ▲                                                │                │
│          │ AcrPull Role                                   │                │
│          └────────────────────────────────────────────────┘                │
│                                                                             │
│  ┌─────────────────┐     ┌─────────────────┐                               │
│  │  Log Analytics  │────▶│  Application    │                               │
│  │  Workspace      │     │  Insights       │                               │
│  └─────────────────┘     └─────────────────┘                               │
│                                                                             │
│  ┌─────────────────┐                                                       │
│  │  Azure AI       │                                                       │
│  │  Services       │  GPT-4 Model Deployment                               │
│  │  (S0 SKU)       │                                                       │
│  └─────────────────┘                                                       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Resources Provisioned

| Resource | Name | SKU | Purpose |
|----------|------|-----|---------|
| Log Analytics Workspace | law-zavastore-dev | PerGB2018 | Centralized logging |
| Application Insights | ai-zavastore-dev | - | Application monitoring |
| Azure Container Registry | acrzavastoredev | Basic | Container image storage |
| App Service Plan | asp-zavastore-dev | B1 (Linux) | Compute for web app |
| Web App for Containers | app-zavastore-dev | - | Host containerized app |
| Azure AI Services | ais-zavastore-dev | S0 | GPT-4 and AI capabilities |

## Estimated Monthly Costs (Dev Environment)

| Resource | Estimated Cost/Month |
|----------|---------------------|
| App Service Plan B1 | ~$13 |
| Azure Container Registry Basic | ~$5 |
| Log Analytics (5GB) | ~$2.30 |
| Application Insights | Free tier (first 5GB) |
| Azure AI Services S0 | Pay-per-use |
| **Total (Base)** | **~$20-25/month** |

> **Note:** AI Services costs depend on usage. GPT-4 is billed per 1K tokens.

## Deployment Workflow

### Prerequisites

1. Azure subscription with appropriate permissions
2. Azure CLI installed (`az --version`)
3. Azure Developer CLI installed (`azd version`)
4. GitHub CLI (optional, for GitHub Actions setup)

### Option 1: Deploy with Azure Developer CLI (Recommended)

```bash
# Login to Azure
azd auth login

# Initialize environment (first time only)
azd init

# Provision infrastructure and deploy
azd up
```

### Option 2: Deploy with Azure CLI

```bash
# Login to Azure
az login

# Create resource group
az group create --name rg-zavastore-dev-westus3 --location westus3

# Deploy Bicep template
az deployment group create \
  --resource-group rg-zavastore-dev-westus3 \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam
```

### Option 3: GitHub Actions (CI/CD)

The repository includes a GitHub Actions workflow that:
1. Builds the Docker image using `az acr build` (no local Docker required)
2. Pushes the image to Azure Container Registry
3. Deploys to Azure App Service

#### Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `AZURE_CLIENT_ID` | Service Principal Client ID |
| `AZURE_TENANT_ID` | Azure AD Tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID |

#### Setting up Workload Identity Federation

```bash
# Create service principal
az ad sp create-for-rbac --name "zavastore-github-actions" --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/rg-zavastore-dev-westus3 \
  --sdk-auth

# Configure federated credentials for GitHub Actions
az ad app federated-credential create \
  --id {app-id} \
  --parameters '{"name":"github-main","issuer":"https://token.actions.githubusercontent.com","subject":"repo:Zava-app-modernization/TechWorkshop-L300-GitHub-Copilot-and-platform:ref:refs/heads/main","audiences":["api://AzureADTokenExchange"]}'
```

## Building Container Images (No Local Docker Required)

### Using Azure Container Registry Build

```bash
# Build and push image using ACR (cloud-based build)
az acr build \
  --registry acrzavastoredev \
  --image zavastore:latest \
  --file Dockerfile \
  .
```

### Using GitHub Actions

Push to `main` or `dev` branch triggers automatic build and deployment.

## Security Features

- **Managed Identity**: Web App uses system-assigned managed identity
- **RBAC for ACR**: AcrPull role assigned to Web App identity (no passwords)
- **HTTPS Only**: All traffic encrypted with TLS 1.2+
- **FTPS Disabled**: No FTP access to web app

## Monitoring

### Application Insights

- Automatic instrumentation enabled
- Connection string injected via app settings
- View metrics in Azure Portal → Application Insights → ai-zavastore-dev

### Log Analytics

- App Service logs collected automatically
- Query logs using KQL in Log Analytics workspace

```kusto
// Example: View recent HTTP requests
AppServiceHTTPLogs
| where TimeGenerated > ago(1h)
| summarize count() by CsMethod, ScStatus
| order by count_ desc
```

## Azure AI Services

### Deployed Models

| Model | Version | Capacity |
|-------|---------|----------|
| GPT-4 | 0613 | 10 TPM |

### Using the AI Services Endpoint

```bash
# Get the endpoint
az cognitiveservices account show \
  --name ais-zavastore-dev \
  --resource-group rg-zavastore-dev-westus3 \
  --query properties.endpoint

# Get the API key (for development only - use managed identity in production)
az cognitiveservices account keys list \
  --name ais-zavastore-dev \
  --resource-group rg-zavastore-dev-westus3
```

## Cleanup

```bash
# Delete all resources
az group delete --name rg-zavastore-dev-westus3 --yes --no-wait

# Or using AZD
azd down
```

## File Structure

```
infra/
├── main.bicep          # Main orchestration template
├── main.bicepparam     # Parameter file for dev environment
└── README.md           # This file

.github/
└── workflows/
    └── build-deploy.yml  # CI/CD workflow

Dockerfile              # Multi-stage Docker build
azure.yaml              # Azure Developer CLI configuration
```

## Troubleshooting

### Common Issues

1. **ACR build fails**: Ensure the service principal has `AcrPush` role on the registry
2. **Web App can't pull image**: Verify `AcrPull` role assignment completed successfully
3. **AI Services deployment fails**: Check region quota for AI Services in westus3

### Useful Commands

```bash
# Check web app logs
az webapp log tail --name app-zavastore-dev --resource-group rg-zavastore-dev-westus3

# Check container settings
az webapp config container show --name app-zavastore-dev --resource-group rg-zavastore-dev-westus3

# Restart web app
az webapp restart --name app-zavastore-dev --resource-group rg-zavastore-dev-westus3
```
