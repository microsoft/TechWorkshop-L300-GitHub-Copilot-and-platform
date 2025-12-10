# Azure Infrastructure Plan for ZavaStorefront Web Application
**Issue #1**: Provision Azure infrastructure for ZavaStorefront web application with Bicep and AZD (dev environment)

---

## 1. Overview

This plan outlines the Azure infrastructure required to deploy the ZavaStorefront web application in a development environment. The deployment will be fully automated using **Azure Developer CLI (AZD)** and **Bicep** templates, ensuring Infrastructure-as-Code best practices.

### Key Principles
- Single resource group in `westus3` region
- Bicep-based infrastructure definition
- AZD-driven orchestrated deployment
- Docker-based App Service deployment via Azure Container Registry
- RBAC-based authentication (no password credentials)
- Full observability with Application Insights

---

## 2. Azure Resources Architecture

### 2.1 Resource Group
- **Name**: `rg-zava-storefront-dev`
- **Region**: `westus3`
- **Purpose**: Container for all related resources

### 2.2 Azure Container Registry (ACR)
- **Name**: `crZavaStorefrontDev` (globally unique)
- **SKU**: Standard
- **Region**: `westus3`
- **Purpose**: Store Docker images for the ZavaStorefront application
- **Authentication**: Azure RBAC (no password-based access)
- **Admin Access**: Disabled (using RBAC instead)

### 2.3 App Service Plan
- **Name**: `asp-zava-storefront-dev`
- **Region**: `westus3`
- **OS**: Linux
- **SKU**: B2 (recommended for dev) or B3 for more capacity
- **Purpose**: Hosting environment for the web application

### 2.4 Web App (App Service)
- **Name**: `app-zava-storefront-dev`
- **Region**: `westus3`
- **Runtime Stack**: .NET 8 (Dockerfile-based custom container)
- **Container Source**: Azure Container Registry
- **Authentication**: Managed Identity with RBAC
- **Purpose**: Host the ZavaStorefront application

### 2.5 Application Insights
- **Name**: `appinsights-zava-storefront-dev`
- **Region**: `westus3`
- **Purpose**: Monitor application performance, logs, and telemetry

### 2.6 Microsoft Foundry (AI Models)
- **Available Models**: 
  - GPT-4
  - Phi (Microsoft's open-source LLM)
- **Region Availability**: westus3
- **Purpose**: Enable AI capabilities for the application (future use)

### 2.7 Supporting Resources
- **Key Vault** (optional but recommended)
  - Store sensitive configuration and secrets
  - Enable managed identity access
  
- **Log Analytics Workspace**
  - Central logging and analytics for Application Insights
  - Query application logs and performance metrics

---

## 3. Deployment Architecture

```
┌─────────────────────────────────────────────────┐
│         Azure Resource Group (westus3)          │
│         rg-zava-storefront-dev                  │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │  Azure Container Registry (ACR)          │  │
│  │  crZavaStorefrontDev                     │  │
│  │  • Docker images storage                 │  │
│  │  • RBAC-based access                     │  │
│  └──────────────┬───────────────────────────┘  │
│                 │ (pull images via MI)        │
│  ┌──────────────▼───────────────────────────┐  │
│  │  App Service Plan (Linux)                │  │
│  │  asp-zava-storefront-dev                 │  │
│  └──────────────┬───────────────────────────┘  │
│                 │                              │
│  ┌──────────────▼───────────────────────────┐  │
│  │  Web App / App Service                   │  │
│  │  app-zava-storefront-dev                 │  │
│  │  • .NET 8 in Docker container            │  │
│  │  • Managed Identity for ACR access       │  │
│  │  • Application Insights connected        │  │
│  └──────────────┬───────────────────────────┘  │
│                 │ (telemetry)                 │
│  ┌──────────────▼───────────────────────────┐  │
│  │  Application Insights                    │  │
│  │  appinsights-zava-storefront-dev         │  │
│  │  • Performance monitoring                │  │
│  │  • Log aggregation                       │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │  Log Analytics Workspace                 │  │
│  │  • Central logs storage                  │  │
│  │  • Analytical queries                    │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  ┌──────────────────────────────────────────┐  │
│  │  Key Vault (optional)                    │  │
│  │  • Secrets and configuration             │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
└─────────────────────────────────────────────────┘
         │
         └─────────────────────────────────────┐
                                               │
                   ┌──────────────────────────┐▼──┐
                   │  Microsoft Foundry (AI)   │   │
                   │  • GPT-4 API              │   │
                   │  • Phi Model              │   │
                   └───────────────────────────┘   │
```

---

## 4. Bicep Template Structure

### 4.1 File Organization
```
infra/
├── main.bicep                    # Entry point - orchestrates all resources
├── modules/
│   ├── resource-group.bicep      # Resource group definition
│   ├── container-registry.bicep  # ACR configuration
│   ├── app-service-plan.bicep    # App Service Plan setup
│   ├── app-service.bicep         # Web App configuration
│   ├── app-insights.bicep        # Application Insights setup
│   ├── key-vault.bicep           # Key Vault (optional)
│   └── log-analytics.bicep       # Log Analytics Workspace
├── parameters.bicep              # Parameter definitions
└── bicepparam
    └── main.bicepparam           # Parameter values for dev environment
```

### 4.2 Key Bicep Features to Implement
1. **Managed Identity**: Service Principal for App Service to access ACR
2. **RBAC Assignment**: `AcrPull` role for Managed Identity on ACR
3. **Environment Variables**: Configuration for Application Insights instrumentation key
4. **Outputs**: Export resource IDs and endpoints for post-deployment setup
5. **Symbolic Names**: Use consistent naming convention with environment suffix

---

## 5. Azure Developer CLI (AZD) Integration

### 5.1 AZD Project Structure
```
azure.yaml                        # AZD project configuration
.azure/
├── config.json                   # Environment configuration
├── .env                          # Local environment variables
└── dev/                          # Dev environment config
    └── config.json               # Dev-specific settings

infra/                            # Bicep templates (as above)
src/                              # Application source code
```

### 5.2 AZD Workflow
1. **Initialize**: `azd init` - Create AZD project structure
2. **Configure**: Set up environment variables and parameters
3. **Provision**: `azd provision` - Deploy Azure resources via Bicep
4. **Deploy**: `azd deploy` - Build and push Docker image, deploy to App Service

---

## 6. Security & Access Control

### 6.1 Authentication Strategy
| Component | Authentication | Details |
|-----------|---|---|
| App Service → ACR | Managed Identity (RBAC) | AcrPull role assignment |
| App Service → Logs | Managed Identity | Application Insights access |
| Key Vault (if used) | Managed Identity | Key Vault Secrets User role |
| Developer Access | Azure CLI / Service Principal | For deployment via AZD |

### 6.2 Networking Considerations (Future Enhancements)
- Virtual Network (optional for dev)
- App Service regional vnet integration (optional)
- Private ACR endpoints (optional for production)

---

## 7. Monitoring & Observability

### 7.1 Application Insights Configuration
- **Instrumentation Key**: Auto-configured in App Service
- **Metrics**: CPU, Memory, HTTP requests, response times
- **Logs**: Application logs, dependency tracking
- **Alerts**: Configure thresholds for critical events

### 7.2 Log Analytics Queries
Example queries to implement:
```kusto
// Request duration by endpoint
requests
| where duration > 1000
| summarize count() by url

// Exception tracking
exceptions
| summarize count() by type, problemId
| order by count_ desc

// Performance metrics
customMetrics
| summarize avg(value) by name
```

---

## 8. Microsoft Foundry Integration (Future)

### 8.1 Prerequisites
- Foundry account setup
- API key configuration in Key Vault
- Azure OpenAI or Foundry SDK integration in application code

### 8.2 Models Available in westus3
- **GPT-4**: For advanced language understanding and generation
- **Phi**: Lightweight alternative for edge scenarios

### 8.3 Implementation Path
1. Configure Foundry credentials in Key Vault
2. Update app configuration to load Foundry endpoints
3. Implement AI service wrapper in C# application
4. Add monitoring for AI API calls in Application Insights

---

## 9. Deployment Steps

### Phase 1: Infrastructure Setup (via Bicep + AZD)
1. ✅ Create Bicep templates in `infra/` directory
2. ✅ Configure `azure.yaml` for AZD project
3. ✅ Set up parameter files for dev environment
4. ✅ Initialize AZD project
5. ✅ Run `azd provision` to create all resources

### Phase 2: Application Deployment
1. ✅ Build Docker image from `src/Dockerfile`
2. ✅ Push image to ACR via `azd deploy`
3. ✅ Configure App Service container settings
4. ✅ Enable Application Insights monitoring
5. ✅ Verify connectivity and health

### Phase 3: Validation & Testing
1. ✅ Test web application access
2. ✅ Verify container logs in App Service
3. ✅ Check Application Insights telemetry
4. ✅ Validate ACR image pull via Managed Identity
5. ✅ Test monitoring alerts

### Phase 4: Documentation & Handoff
1. ✅ Document all resource names and endpoints
2. ✅ Create runbooks for common operations
3. ✅ Document rollback procedures
4. ✅ Provide troubleshooting guide

---

## 10. Cost Estimation (Dev Environment)

| Resource | SKU | Est. Monthly Cost |
|----------|-----|-------------------|
| App Service Plan | B2 | $33 |
| Azure Container Registry | Standard | $10 |
| Application Insights | (included with App Service) | $0 |
| Log Analytics | (linked to App Insights) | $2-5 |
| Key Vault (optional) | Standard | $0.6 |
| **Total** | | **~$46** |

*Note: Costs are estimates and may vary based on actual usage and data ingestion.*

---

## 11. Rollback & Disaster Recovery

### 11.1 Rollback Strategy
1. **Resource Group Deletion**: Delete entire RG to clean up all resources
   ```bash
   az group delete --name rg-zava-storefront-dev --yes
   ```

2. **Resource Redeployment**: Re-run `azd provision` to recreate

3. **Image Rollback**: Deploy previous Docker image version to App Service

### 11.2 Backup Strategy
- **ACR Images**: All images retained in registry
- **Application Settings**: Exported from App Service configuration
- **Infrastructure Code**: Version controlled in Git

---

## 12. Next Steps & Action Items

- [ ] Create Bicep template files in `infra/` directory
- [ ] Define parameter files for dev environment
- [ ] Set up `azure.yaml` for AZD configuration
- [ ] Create Dockerfile for ZavaStorefront application
- [ ] Initialize AZD project with `azd init`
- [ ] Test `azd provision` command
- [ ] Configure GitHub Actions for CI/CD
- [ ] Document post-deployment configuration steps
- [ ] Set up monitoring and alerting rules
- [ ] Plan Microsoft Foundry integration for Phase 2

---

## 13. References & Documentation

- [Azure Developer CLI (AZD) Overview](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/azd-overview)
- [Bicep Language Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview)
- [App Service with Docker Containers](https://learn.microsoft.com/en-us/azure/app-service/configure-custom-container)
- [Azure Container Registry Documentation](https://learn.microsoft.com/en-us/azure/container-registry/)
- [Application Insights for .NET Applications](https://learn.microsoft.com/en-us/azure/azure-monitor/app/asp-net-core)
- [Managed Identity for Azure Resources](https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview)
- [Microsoft Foundry](https://foundry.microsoft.com/)

---

**Plan Version**: 1.0
**Last Updated**: December 10, 2025
**Status**: Ready for Implementation
