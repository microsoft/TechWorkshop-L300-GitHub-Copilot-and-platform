# ZavaStorefront - Azure Infrastructure

Infrastructure-as-code for the **ZavaStorefront** application using [Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/) and [Azure Developer CLI (AZD)](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/).

## Architecture

All resources are deployed into a single resource group in **westus3**:

| Resource | Type | Purpose |
|---|---|---|
| Azure Container Registry (ACR) | `Basic` SKU | Stores Docker container images |
| App Service Plan | `B1` Linux | Hosts the web app |
| Web App for Containers | Linux | Runs the ZavaStorefront .NET app |
| Application Insights | Workspace-based | Application monitoring & telemetry |
| Log Analytics Workspace | `PerGB2018` | Backend for Application Insights |
| AI Foundry Hub | `Basic` | AI model orchestration |
| AI Foundry Project | `Basic` | Dev project linked to Hub |
| Azure AI Services | `S0` | GPT-4o + Phi-4 model deployments |

## Security Design

- **No password-based ACR pulls** — Web App uses its **system-assigned managed identity** with the `AcrPull` role on ACR
- Admin credentials are **disabled** on ACR
- HTTPS enforced on the Web App

## Module Structure

```
infra/
├── main.bicep                  # Root orchestration template
├── main.parameters.json        # AZD parameter bindings
└── modules/
    ├── acr.bicep               # Azure Container Registry
    ├── logAnalytics.bicep      # Log Analytics Workspace
    ├── appInsights.bicep       # Application Insights
    ├── appService.bicep        # App Service Plan + Web App
    ├── roleAssignment.bicep    # AcrPull role for Web App identity
    └── aiFoundry.bicep         # AI Hub, Project, AI Services + model deployments
```

## Prerequisites

- [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd) installed
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) installed
- Active Azure subscription with quota for AI Foundry models in `westus3`

## Deployment

### 1. Authenticate

```bash
azd auth login
az login
```

### 2. Initialize environment

```bash
azd init --environment dev
```

Set the location when prompted: `westus3`

### 3. Preview infrastructure

```bash
azd provision --preview
```

### 4. Provision infrastructure

```bash
azd provision
```

### 5. Build & push container image (no local Docker needed — uses ACR Tasks)

```bash
az acr build --registry <acr-name> --image zava-storefront:latest .
```

### 6. Deploy application

```bash
azd deploy
```

### 7. Full provision + deploy in one command

```bash
azd up
```

## Outputs

After provisioning, AZD exports these values to `.azure/<env>/.env`:

| Output | Description |
|---|---|
| `AZURE_CONTAINER_REGISTRY_ENDPOINT` | ACR login server URL |
| `SERVICE_WEB_URI` | Web App public URL |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | App Insights connection string |
| `AZURE_AI_SERVICES_ENDPOINT` | AI Services endpoint for GPT-4o / Phi-4 |

## Cost Notes (Dev Environment)

| Resource | Est. Monthly Cost |
|---|---|
| ACR Basic | ~$5 |
| App Service B1 | ~$13 |
| Log Analytics (low volume) | ~$2 |
| Application Insights | Pay-per-use |
| AI Foundry Hub | Free |
| AI Services (S0) | Pay-per-use |

## Teardown

```bash
azd down
```
