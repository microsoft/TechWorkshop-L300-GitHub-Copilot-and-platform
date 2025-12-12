# Azure Infrastructure Plan - ZavaStorefront (Issue #2)

## Overview
Comprehensive plan for provisioning Azure infrastructure to deploy the ZavaStorefront .NET 6.0 ASP.NET MVC e-commerce application in a development environment using Azure Container Apps.

**Status**: ✅ Complete - Infrastructure deployed and operational

---

## Project Details
- **Application**: ZavaStorefront
- **Framework**: ASP.NET Core 6.0 MVC
- **Type**: E-commerce web application
- **Environment**: Development (dev)
- **Deployment Target**: Azure Container Apps (serverless containers)
- **Region**: West US 3 (westus3)
- **Resource Group**: `rg-dev`

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Azure Subscription                        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  Resource Group  │
                    │     (rg-dev)     │
                    └──────────────────┘
                              │
            ┌─────────────────┼─────────────────┐
            │                 │                 │
            ▼                 ▼                 ▼
    ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
    │  Container   │  │   Container  │  │  Container   │
    │   Registry   │  │   Apps       │  │  Environment │
    │ (ACR)        │  │  (aca-*)     │  │  (aze-*)     │
    └──────────────┘  └──────────────┘  └──────────────┘
            │                 │                 │
            └─────────────────┼─────────────────┘
                              │
            ┌─────────────────┼─────────────────┐
            │                 │                 │
            ▼                 ▼                 ▼
    ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
    │   Log        │  │  Managed     │  │   User       │
    │  Analytics   │  │  Identity    │  │  Assigned    │
    │ (law-*)      │  │  (uami-*)    │  │  Identity    │
    └──────────────┘  └──────────────┘  └──────────────┘
```

---

## Azure Resources Provisioned

### Core Compute
| Resource | Name Pattern | Purpose | Details |
|----------|--------------|---------|---------|
| **Container Apps Environment** | `aze-{token}` | Managed environment for container apps | Serverless container orchestration |
| **Container App** | `aca-{token}` | Web application runtime | .NET 6.0 ASP.NET MVC app, 1-3 replicas auto-scaling |

### Container & Registry
| Resource | Name Pattern | Purpose | Details |
|----------|--------------|---------|---------|
| **Container Registry** | `acr{token}` | Private Docker image registry | Stores built application images |
| **User Assigned Identity** | `uami-{token}` | Authentication for ACR pull | Enables secure image retrieval |

### Monitoring & Logging
| Resource | Name Pattern | Purpose | Details |
|----------|--------------|---------|---------|
| **Log Analytics Workspace** | `law-{token}` | Centralized logging | Captures application and infrastructure logs |

### Networking
| Resource | Purpose |
|----------|---------|
| **Azure Container Apps** | HTTPS-only ingress (port 443 → 8080) |

*Note: {token} = first 12 characters of `uniqueString(subscriptionId, location, environment)`*

---

## Infrastructure as Code (IaC)

### Bicep Modules
```
infra/
├── main.bicep                          # Subscription-scoped orchestration
├── main.parameters.json                # Parameter file with AZD variable substitution
└── modules/
    ├── containerApp.bicep              # Container app with ingress, scaling, env vars
    ├── containerAppEnvironment.bicep   # Managed environment for container apps
    ├── containerRegistry.bicep         # ACR with AcrPull role assignment
    ├── logAnalyticsWorkspace.bicep     # Log Analytics workspace
    └── userAssignedIdentity.bicep      # Managed identity for ACR authentication
```

### AZD Configuration
- **Tool**: Azure Developer CLI (azd)
- **Scope**: Subscription-level (creates resource group)
- **Template**: Bicep Infrastructure as Code
- **Environment**: `.azure/dev/.env`

### Key Features
- ✅ Subscription-scoped deployment
- ✅ Automatic resource group creation
- ✅ AZD-compliant naming conventions
- ✅ User-assigned managed identity for secure ACR access
- ✅ AcrPull role assignment (GUID: 7f951dda-4ed3-4680-a7ca-43fe172d538d)
- ✅ Auto-scaling based on CPU metrics
- ✅ HTTPS-only ingress for security
- ✅ Comprehensive logging to Log Analytics

---

## Deployment Process

### Prerequisites
1. Azure subscription (`f95d461a-e712-4c78-89bf-41079cc7ccea`)
2. Azure Developer CLI (`azd`) installed
3. Docker installed (for local building)
4. .NET 6.0 SDK (optional, for local testing)

### Deployment Steps

**1. Initialize AZD Environment**
```bash
cd c:\Users\ruchidalal\ZavaLabFork
azd auth login
azd env new dev
```

**2. Configure Environment**
Environment variables in `.azure/dev/.env`:
```
AZURE_ENV_NAME=dev
AZURE_LOCATION=westus3
AZURE_SUBSCRIPTION_ID=f95d461a-e712-4c78-89bf-41079cc7ccea
AZURE_RESOURCE_GROUP=rg-dev
```

**3. Provision Infrastructure**
```bash
azd provision
```
This deploys all resources to Azure:
- Resource group in West US 3
- Container Apps environment
- Container Registry
- Log Analytics workspace
- Managed identities and role assignments

**4. Build and Push Docker Image**
```bash
azd deploy
```
This:
- Builds the Docker image
- Pushes to Azure Container Registry
- Updates Container App with new image
- Application becomes accessible via FQDN

**5. Deploy to Azure**
```bash
azd up
```
Combines provision + deploy in one command

### Cleanup
```bash
azd down
```
Removes all Azure resources (after confirming)

---

## Application Configuration

### Dockerfile
- **Location**: `src/Dockerfile`
- **Base Image**: `mcr.microsoft.com/dotnet/aspnet:6.0` (runtime)
- **Build Image**: `mcr.microsoft.com/dotnet/sdk:6.0`
- **Port**: 8080 (HTTP)
- **HTTPS**: Handled by Azure Container Apps ingress

### Environment Variables (Container App)
```
ASPNETCORE_URLS=http://+:8080
ASPNETCORE_ENVIRONMENT=Development
```

### Application Features
- Product catalog management
- Shopping cart functionality
- Checkout flow
- MVC pattern with controllers, models, views
- Static assets (CSS, JS, images)

---

## CI/CD Pipeline

### GitHub Actions Workflow
- **File**: `.github/workflows/build-deploy.yml`
- **Trigger**: Push to `main` branch (or manual dispatch)
- **Steps**:
  1. Checkout code
  2. Authenticate to Azure
  3. Login to Container Registry
  4. Build and push Docker image (with git SHA tag)
  5. Update Container App with new image

### Required GitHub Secrets
```
AZURE_SUBSCRIPTION_ID          # Subscription ID
AZURE_CLIENT_ID                # Service principal ID
AZURE_TENANT_ID                # Azure tenant ID
AZURE_CONTAINER_REGISTRY_NAME  # ACR name (without .azurecr.io)
AZURE_RESOURCE_GROUP           # Resource group name
RESOURCE_TOKEN                 # Token for naming resources
```

---

## Monitoring & Logging

### Log Analytics Workspace
- **Workspace Name**: `law-{token}`
- **SKU**: PerGB2018
- **Retention**: 30 days
- **Captures**: Application logs, infrastructure metrics, container runtime logs

### Application Insights Integration
Container Apps automatically sends logs to Log Analytics for:
- Request tracking
- Performance metrics
- Error diagnostics
- Container runtime events

### Accessing Logs
1. Azure Portal → Resource Group → Log Analytics Workspace
2. Run KQL queries to analyze logs
3. Set up alerts based on log patterns

---

## Security

### Identity & Access Control
- **User-Assigned Managed Identity**: `uami-{token}`
  - Secures ACR image pulls
  - No passwords/connection strings needed
  - AcrPull role assigned via Bicep

### Network Security
- **HTTPS-only Ingress**: All traffic encrypted
- **Private Container Registry**: No public endpoint
- **Managed Identity**: No stored credentials

### Image Security
- Docker image built from verified Microsoft base images
- Stored in private Azure Container Registry
- Signed container images recommended

---

## Cost Considerations

### Estimated Monthly Costs (Dev Environment)
| Resource | Tier | Est. Cost |
|----------|------|-----------|
| Container Apps (1-3 replicas, 0.5 CPU) | Consumption | $15-30 |
| Container Registry (Basic) | Basic | $5-10 |
| Log Analytics (Pay-as-you-go) | 5GB/day retention | $10-15 |
| **Total** | | **$30-55/month** |

### Cost Optimization
- Container Apps auto-scales to 1 replica when idle
- Log Analytics 30-day retention limits storage
- Basic ACR tier suitable for dev environment
- No VM or App Service compute charges

---

## Troubleshooting

### Common Issues

**1. Container App fails to start**
- Check Log Analytics for error details
- Verify Docker image is in Container Registry
- Ensure managed identity has AcrPull permissions

**2. Deployment timeout**
- Container Apps take 2-3 minutes to deploy
- Check Azure Portal for resource status
- Review provisioning logs: `azd provision --debug`

**3. Image pull failures**
- Verify managed identity has AcrPull role
- Check ACR has the image: `az acr repository list --name {acrName}`
- Verify ACR firewall rules aren't blocking Container Apps

### Useful Commands
```bash
# View deployment logs
azd logs

# Check resource status
az resource list --resource-group rg-dev

# View container app logs
az containerapp logs show --name aca-{token} --resource-group rg-dev

# Access Log Analytics
az monitor log-analytics query --workspace-id {workspaceId} \
  --analytics-query "ContainerAppSystemLogs_CL | take 10"
```

---

## Next Steps & Recommendations

### Immediate (Completed)
- ✅ Infrastructure provisioned
- ✅ Container Registry created
- ✅ Container Apps deployed
- ✅ Monitoring configured

### Short-term (Recommended)
1. Configure GitHub Secrets for CI/CD pipeline
2. Test GitHub Actions deployment workflow
3. Verify application accessibility via Container App FQDN
4. Set up Log Analytics alerts for errors
5. Document application-specific environment variables

### Medium-term (Enhancement)
1. Enable Application Insights for detailed APM
2. Configure auto-scaling policies based on metrics
3. Implement health check endpoints
4. Set up custom domain (if applicable)
5. Configure managed certificates for HTTPS

### Long-term (Production)
1. Create staging environment (separate resource group)
2. Implement blue-green deployment strategy
3. Add Azure API Management layer
4. Implement Azure Front Door for CDN
5. Configure Azure SQL Database for data persistence

---

## Documentation & References

### Azure Container Apps
- [Azure Container Apps Documentation](https://learn.microsoft.com/azure/container-apps/)
- [Container Apps Billing](https://learn.microsoft.com/azure/container-apps/billing)

### Azure Developer CLI
- [Azure Developer CLI Docs](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [AZD Reference](https://learn.microsoft.com/cli/azure/dev)

### Bicep
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Bicep Best Practices](https://learn.microsoft.com/azure/azure-resource-manager/bicep/best-practices)

### CI/CD
- [GitHub Actions for Azure](https://github.com/marketplace/actions/azure-login)
- [Container Registry Push/Pull](https://learn.microsoft.com/azure/container-registry/container-registry-get-started-docker-cli)

---

## Files & Configuration

### Repository Structure
```
ZavaLabFork/
├── .azure/
│   └── dev/
│       └── .env                    # Environment configuration
├── .github/
│   └── workflows/
│       ├── build-deploy.yml        # CI/CD pipeline
│       └── README.md               # Workflow documentation
├── infra/
│   ├── main.bicep                 # Main orchestration
│   ├── main.parameters.json       # Parameters
│   └── modules/                   # Bicep modules
├── src/
│   ├── Dockerfile                 # Container image definition
│   ├── .dockerignore              # Docker build exclusions
│   └── ZavaStorefront.csproj      # .NET project file
└── azure.yaml                     # AZD configuration
```

### Configuration Files
- `.azure/dev/.env`: Environment variables (subscription, location, resource group)
- `azure.yaml`: AZD project configuration
- `infra/main.bicep`: Infrastructure definition
- `infra/main.parameters.json`: Template parameters with AZD variable substitution
- `.github/workflows/build-deploy.yml`: GitHub Actions CI/CD pipeline

---

## Summary

This infrastructure deployment provides:
- ✅ **Fully serverless** - No VMs to manage
- ✅ **Auto-scaling** - Handles variable load
- ✅ **Private registry** - Secure image storage
- ✅ **Comprehensive logging** - 30-day retention
- ✅ **Infrastructure as Code** - Repeatable, version-controlled
- ✅ **CI/CD ready** - GitHub Actions integration
- ✅ **Cost-effective** - ~$30-55/month for dev environment
- ✅ **Secure** - HTTPS, managed identities, no stored credentials

**Status**: Ready for production-like testing in development environment.
