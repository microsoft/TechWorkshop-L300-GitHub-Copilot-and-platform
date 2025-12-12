# Azure Infrastructure Bicep Files - Issue #2

Complete Infrastructure as Code for ZavaStorefront Azure deployment using Bicep.

## File Structure

```
infra/
├── main.bicep                         # Main orchestration file
├── main.parameters.json               # Template parameters
├── main.json                          # Generated ARM template (auto-generated)
├── modules/
│   ├── containerApp.bicep
│   ├── containerAppEnvironment.bicep
│   ├── containerRegistry.bicep
│   ├── logAnalyticsWorkspace.bicep
│   └── userAssignedIdentity.bicep
└── README.md                          # This file
```

---

## Bicep Files Overview

### main.bicep
**Purpose**: Main orchestration at subscription scope

**Responsibilities**:
- Create resource group
- Generate unique resource tokens
- Instantiate all infrastructure modules
- Provide outputs for AZD integration

**Key Features**:
- Subscription-scoped deployment
- Automatic resource group creation
- Module orchestration and dependency management
- Proper output definitions (RESOURCE_GROUP_ID, AZURE_CONTAINER_REGISTRY_ENDPOINT, AZURE_CONTAINER_APP_FQDN)

**Dependencies**: All 5 modules

---

### main.parameters.json
**Purpose**: Parameters file for template deployment

**Content**:
```json
{
  "environmentName": "${AZURE_ENV_NAME}",
  "location": "${AZURE_LOCATION}"
}
```

**AZD Variable Substitution**:
- `${AZURE_ENV_NAME}` → Environment name (e.g., "dev")
- `${AZURE_LOCATION}` → Azure region (e.g., "westus3")

---

### modules/userAssignedIdentity.bicep
**Purpose**: Create managed identity for secure resource access

**Resources Created**:
- User-assigned managed identity

**Inputs**:
- `location` (string) - Azure region
- `identityName` (string) - Identity resource name

**Outputs**:
- `id` - Full resource ID
- `principalId` - Object ID for role assignments

**Usage**: Used by Container App for ACR authentication

---

### modules/containerAppEnvironment.bicep
**Purpose**: Create managed environment for container applications

**Resources Created**:
- Azure Container Apps managed environment

**Inputs**:
- `location` (string) - Azure region
- `environmentName` (string) - Environment identifier

**Outputs**:
- `id` - Environment resource ID
- `name` - Environment name

**Key Features**:
- Serverless container orchestration
- Infrastructure for container deployments
- Implicit logging support

---

### modules/containerRegistry.bicep
**Purpose**: Create private container registry with access control

**Resources Created**:
- Azure Container Registry (Basic tier)
- Role assignment for AcrPull access

**Inputs**:
- `location` (string) - Azure region
- `registryName` (string) - Registry name (must be < 50 chars)
- `acrPushPrincipalId` (string) - Principal ID for role assignment

**Outputs**:
- `loginServer` - Registry endpoint (used by Container App)
- `id` - Registry resource ID

**Security**:
- Admin user disabled (use managed identity)
- AcrPull role (GUID: 7f951dda-4ed3-4680-a7ca-43fe172d538d)
- Public network access enabled (configurable)

**Tier**: Basic ($5-10/month)
- Webhook support
- AzureCLI automation
- Suitable for dev/test

---

### modules/logAnalyticsWorkspace.bicep
**Purpose**: Create centralized logging for monitoring

**Resources Created**:
- Log Analytics workspace

**Inputs**:
- `location` (string) - Azure region
- `workspaceName` (string) - Workspace name
- `environmentName` (string) - Environment identifier

**Outputs**:
- `id` - Workspace resource ID
- `customerId` - Workspace ID for agent configuration

**Configuration**:
- SKU: PerGB2018 (pay-as-you-go)
- Retention: 30 days
- Auto-integrates with Container Apps

**Capabilities**:
- Application logs
- Container runtime logs
- Performance metrics
- Alert and analytics queries (KQL)

---

### modules/containerApp.bicep
**Purpose**: Deploy .NET application as container app

**Resources Created**:
- Container App with full configuration

**Inputs**:
- `location` (string) - Azure region
- `environmentName` (string) - Environment identifier
- `containerAppEnvironmentId` (string) - Reference to environment
- `containerAppName` (string) - App name
- `containerRegistryUrl` (string) - Registry endpoint
- `containerRegistryIdentityId` (string) - Managed identity for auth
- `containerImage` (string) - Container image to deploy (default: hello world)

**Outputs**:
- `fqdn` - Fully qualified domain name for application access
- `id` - Container App resource ID

**Configuration**:

**Ingress**:
- External: true (publicly accessible)
- Target port: 8080 (ASP.NET Core default)
- Insecure: false (HTTPS required)
- Traffic weight: 100% to latest revision

**Identity**:
- User-assigned managed identity
- Enables secure image pull from private ACR

**Registries**:
- Private registry configuration
- Managed identity authentication

**Compute**:
- CPU: 0.5 cores
- Memory: 1Gi
- Runtime: Configurable per deployment

**Scaling**:
- Min replicas: 1 (always on)
- Max replicas: 3 (dev), 5 (prod)
- HTTP concurrency-based scaling

**Environment Variables**:
- `ASPNETCORE_ENVIRONMENT=Development`
- `ASPNETCORE_URLS=http://+:8080`

**Tags**:
- `azd-env-name` - Environment identifier
- `azd-service-name=src` - Service identifier

**Default Image**: `mcr.microsoft.com/azuredocs/containerapps-helloworld:latest`
(Replaced during `azd deploy` with actual application image)

---

## Deployment Workflow

### 1. Build Bicep Templates
```bash
az bicep build --file infra/main.bicep --outdir infra
```
Generates `main.json` (ARM template) from Bicep source.

### 2. Preview Deployment
```bash
azd provision --preview
```
Shows resources to be created without actually deploying.

### 3. Provision Infrastructure
```bash
azd provision
```
Deploys all resources to Azure using the Bicep templates.

### 4. Deploy Application
```bash
azd deploy
```
Builds Docker image and updates Container App with new image.

### 5. Combined Deployment
```bash
azd up
```
Runs provision + deploy in sequence.

---

## Resource Dependencies

```
Resource Group (rg-dev)
    ├── User Assigned Identity (uami-*)
    │   └── Used by: Container App, Container Registry
    │
    ├── Container Apps Environment (aze-*)
    │   └── Used by: Container App
    │
    ├── Container Registry (acr*)
    │   ├── Role Assignment (AcrPull)
    │   │   └── Principal: uami-* (User Assigned Identity)
    │   └── Used by: Container App
    │
    ├── Log Analytics Workspace (law-*)
    │   └── Used by: Container App (automatic integration)
    │
    └── Container App (aca-*)
        ├── Depends on: Container Apps Environment
        ├── Uses: User Assigned Identity
        ├── Pulls from: Container Registry
        └── Logs to: Log Analytics Workspace
```

---

## Resource Naming Convention

All resources follow the naming pattern: `{prefix}{uniqueToken}`

**Token Generation**:
```bicep
var resourceToken = uniqueString(subscription().id, location, environmentName)
// Result: 13-character hash, e.g., "duidxq2srj2z"
```

**Resource Names**:
| Resource | Pattern | Example |
|----------|---------|---------|
| Container App | `aca-{token[0:12]}` | `aca-duidxq2srj2z` |
| Container Registry | `acr{token[0:12]}` | `acrduidxq2srj2z` |
| Managed Identity | `uami-{token[0:10]}` | `uami-duidxq2sr` |
| Container Env | `aze-{token[0:12]}` | `aze-duidxq2srj2z` |
| Log Analytics | `law-{token[0:12]}` | `law-duidxq2srj2z` |
| Resource Group | `rg-{env}` | `rg-dev` |

**Benefits**:
- Unique across deployments
- Deterministic (same inputs = same names)
- Complies with Azure naming limits
- Easy to identify by pattern

---

## Security Implementation

### Managed Identity Access
```bicep
identity: {
  type: 'UserAssigned'
  userAssignedIdentities: {
    '${containerRegistryIdentityId}': {}
  }
}
```

### Role-Based Access Control
```bicep
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleId)
    principalId: acrPushPrincipalId
    principalType: 'ServicePrincipal'
  }
}
```

**AcrPull Role GUID**: `7f951dda-4ed3-4680-a7ca-43fe172d538d`

### HTTPS Enforcement
```bicep
ingress: {
  allowInsecure: false  // HTTPS required
  external: true        // Publicly accessible
}
```

### No Admin Keys
```bicep
properties: {
  adminUserEnabled: false  // Use managed identity instead
}
```

---

## Verification Steps

### 1. Bicep Compilation
```bash
az bicep build --file infra/main.bicep --outdir infra
# Should complete without errors
# Generates: infra/main.json
```

### 2. Deployment Preview
```bash
azd provision --preview
# Expected output shows 5 resources to create:
# - Resource Group
# - Container App
# - Container Apps Environment
# - Container Registry
# - Log Analytics Workspace
```

### 3. Parameter Substitution
```bash
# Check .azure/dev/.env
cat .azure/dev/.env
# Should contain: AZURE_ENV_NAME, AZURE_LOCATION, AZURE_SUBSCRIPTION_ID
```

### 4. Template Validation
```bash
az deployment sub validate \
  --location westus3 \
  --template-file infra/main.json \
  --parameters infra/main.parameters.json \
  environmentName=dev \
  location=westus3
```

---

## Monitoring & Debugging

### View Generated ARM Template
```bash
cat infra/main.json  # Generated from Bicep
```

### Check Deployment Status
```bash
az deployment group list \
  --resource-group rg-dev \
  --query "[].{Name: name, State: properties.provisioningState}"
```

### View Resource Details
```bash
az resource list --resource-group rg-dev --output table
```

### Container App Logs
```bash
az containerapp logs show \
  --name aca-duidxq2srj2z \
  --resource-group rg-dev
```

---

## Cost Breakdown (Monthly)

| Resource | Tier | Cost |
|----------|------|------|
| Container Apps | Consumption | $15-30 |
| Container Registry | Basic | $5-10 |
| Log Analytics | PerGB2018 | $10-15 |
| **Total** | | **$30-55** |

*Costs are estimates for dev environment and scale with actual usage.*

---

## Next Steps

1. **Provision**: `azd provision`
2. **Deploy**: `azd deploy`
3. **Test**: Visit Container App FQDN
4. **Monitor**: Check Log Analytics logs
5. **CI/CD**: Configure GitHub Secrets and push to main

---

## References

- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Container Apps](https://learn.microsoft.com/azure/container-apps/)
- [Azure Container Registry](https://learn.microsoft.com/azure/container-registry/)
- [Log Analytics](https://learn.microsoft.com/azure/azure-monitor/logs/log-analytics-overview)
- [Managed Identities](https://learn.microsoft.com/azure/active-directory/managed-identities-azure-resources/)
