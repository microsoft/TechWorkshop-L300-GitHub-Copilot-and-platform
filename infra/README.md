# ZavaStorefront Infrastructure

This folder contains the Bicep templates for deploying the ZavaStorefront application to Azure.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Resource Group (rg-zavastore-dev-westus3)            │
│                                                                             │
│  ┌─────────────────┐   ┌──────────────────┐   ┌────────────────────────┐   │
│  │  Log Analytics  │◄──│ Application      │   │  Azure Container       │   │
│  │  Workspace      │   │ Insights         │   │  Registry (ACR)        │   │
│  └─────────────────┘   └──────────────────┘   └───────────┬────────────┘   │
│                                                           │                 │
│                                                           │ AcrPull         │
│                                                           │ (Managed ID)    │
│                                                           ▼                 │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    Linux App Service                                 │   │
│  │  ┌─────────────────┐   ┌────────────────────────────────────────┐   │   │
│  │  │  App Service    │   │  Web App for Containers                │   │   │
│  │  │  Plan (B1)      │──►│  (ZavaStorefront .NET 6)               │   │   │
│  │  └─────────────────┘   │  - System-assigned Managed Identity    │   │   │
│  │                        │  - HTTPS only                          │   │   │
│  │                        └────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Resources

| Resource | Type | Purpose |
|----------|------|---------|
| Log Analytics Workspace | `Microsoft.OperationalInsights/workspaces` | Centralized logging |
| Application Insights | `Microsoft.Insights/components` | Application monitoring |
| Container Registry | `Microsoft.ContainerRegistry/registries` | Docker image storage |
| App Service Plan | `Microsoft.Web/serverfarms` | Linux hosting plan |
| Web App | `Microsoft.Web/sites` | Container hosting |
| Role Assignment | `Microsoft.Authorization/roleAssignments` | AcrPull permission |

## Files

```
infra/
├── main.bicep                 # Main orchestration template
├── main.parameters.json       # Parameters file for AZD
├── README.md                  # This file
└── modules/
    ├── logAnalytics.bicep     # Log Analytics Workspace
    ├── appInsights.bicep      # Application Insights
    ├── acr.bicep              # Azure Container Registry
    ├── appService.bicep       # App Service Plan + Web App
    └── roleAssignment.bicep   # AcrPull role assignment
```

## Deployment

### Prerequisites

1. [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)
2. [Azure Developer CLI (azd)](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd)
3. An Azure subscription

### Steps

1. **Login to Azure:**
   ```bash
   az login
   azd auth login
   ```

2. **Initialize the environment:**
   ```bash
   azd init
   ```

3. **Preview the deployment:**
   ```bash
   azd provision --preview
   ```

4. **Deploy infrastructure:**
   ```bash
   azd up
   ```

5. **Build and deploy the application:**
   ```bash
   # Build image using ACR Tasks (no local Docker required)
   az acr build --registry <acr-name> --image zavastore:latest .
   ```

## Security Features

- ✅ **Managed Identity**: Web App uses system-assigned managed identity
- ✅ **RBAC Authentication**: No admin credentials for ACR
- ✅ **AcrPull Role**: Minimal permissions for image pull
- ✅ **HTTPS Only**: All traffic encrypted
- ✅ **TLS 1.2**: Minimum TLS version enforced
- ✅ **No Anonymous Pull**: ACR requires authentication

## Cost Optimization (Dev Environment)

- Basic SKU for Container Registry
- B1 tier for App Service Plan
- 30-day log retention
- AlwaysOn disabled

## Environment Variables

The following outputs are available after deployment:

| Variable | Description |
|----------|-------------|
| `AZURE_RESOURCE_GROUP` | Resource group name |
| `AZURE_LOCATION` | Deployment region |
| `AZURE_CONTAINER_REGISTRY_NAME` | ACR name |
| `AZURE_CONTAINER_REGISTRY_ENDPOINT` | ACR login server |
| `AZURE_WEB_APP_NAME` | Web App name |
| `AZURE_WEB_APP_URL` | Application URL |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | App Insights connection string |
