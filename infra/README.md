# ZavaStorefront — Azure Infrastructure

This folder contains [Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview) templates that provision all Azure resources required for the **ZavaStorefront** application. Resources are deployed together into a single resource group using the [Azure Developer CLI (AZD)](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/).

## Resources provisioned

| Resource | SKU / Tier | Purpose |
|---|---|---|
| Log Analytics Workspace | PerGB2018 | Backing store for Application Insights |
| Application Insights | — | Application monitoring |
| Azure Container Registry (ACR) | Basic | Stores Docker container images |
| App Service Plan | B1 (Linux) | Hosts the web application |
| App Service (Web App for Containers) | — | Runs the containerised ASP.NET Core app |
| Azure AI Services (AI Foundry) | S0 | GPT-4 and Phi-3 model access in westus3 |

### Security / RBAC

- The App Service is configured with a **system-assigned managed identity**.
- An `AcrPull` role assignment grants the identity pull access to ACR — **no passwords or admin credentials are used**.
- ACR admin user is **disabled**.

## Folder structure

```
infra/
├── main.bicep               # Root orchestration template
├── main.parameters.json     # AZD parameter mappings
└── modules/
    ├── logAnalytics.bicep   # Log Analytics workspace
    ├── appInsights.bicep    # Application Insights
    ├── acr.bicep            # Azure Container Registry
    ├── appService.bicep     # App Service Plan + Web App
    └── aiFoundry.bicep      # Azure AI Foundry (GPT-4 & Phi)
```

## Prerequisites

- [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd) ≥ 1.9
- Azure subscription with Contributor access
- Subscription quota for Azure AI Services in **westus3**

## Deploy

```bash
# Authenticate
azd auth login

# Provision all infrastructure (preview first)
azd provision --preview
azd provision

# Build & push the container image using ACR Tasks (no local Docker required)
az acr build \
  --registry <ACR_NAME> \
  --image zava-storefront:latest \
  ./src

# Deploy the application
azd deploy
```

Or deploy everything in one command:

```bash
azd up
```

## Container image builds (no local Docker)

ACR Tasks build and push images in the cloud:

```bash
az acr build --registry <ACR_NAME> --image zava-storefront:latest ./src
```

GitHub Actions can also build images using the hosted runner — see `.github/workflows/` for examples.

## Estimated monthly cost (dev)

| Resource | Est. cost |
|---|---|
| App Service Plan B1 | ~$13/month |
| ACR Basic | ~$5/month |
| Log Analytics (minimal data) | ~$0–5/month |
| AI Services S0 | Pay-per-use |

> Costs vary by usage. Use `azd down` to tear down all resources when not in use.
