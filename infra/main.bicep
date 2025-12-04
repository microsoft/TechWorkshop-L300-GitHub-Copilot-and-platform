// Main Bicep template for ZavaStorefront Azure infrastructure
// Provisions all resources for dev environment with container-based deployment
// Uses RBAC for secure communication between services (no passwords)

targetScope = 'resourceGroup'

@minLength(1)
@maxLength(64)
@description('Name of the environment (used for resource naming)')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string = resourceGroup().location

@description('The name of the App Service application')
param appServiceName string = ''

@description('The name of the Container Registry')
param containerRegistryName string = ''

@description('SKU for the App Service Plan')
param appServicePlanSku string = 'B1'

// Generate unique resource token for naming
var resourceToken = uniqueString(subscription().id, resourceGroup().id, location, environmentName)
var tags = {
  'azd-env-name': environmentName
  environment: 'dev'
  project: 'zava-storefront'
}

// ========================================
// User-Assigned Managed Identity
// ========================================
// Used by App Service to authenticate to Container Registry via RBAC
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'azmi${resourceToken}'
  location: location
  tags: tags
}

// ========================================
// Log Analytics Workspace
// ========================================
// Centralized logging for Application Insights and diagnostic settings
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'azlog${resourceToken}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// ========================================
// Application Insights
// ========================================
// Performance monitoring and telemetry for the web application
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'azai${resourceToken}'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

// ========================================
// Azure Container Registry
// ========================================
// Stores Docker images for the application
// RBAC-enabled (no admin user/password)
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: !empty(containerRegistryName) ? containerRegistryName : 'azacr${resourceToken}'
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false // RBAC authentication only
    anonymousPullEnabled: false // Disable anonymous pull access
    publicNetworkAccess: 'Enabled'
  }
}

// ========================================
// App Service Plan (Linux)
// ========================================
// Hosting plan for containerized web app
resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: 'azasp${resourceToken}'
  location: location
  tags: tags
  sku: {
    name: appServicePlanSku
  }
  kind: 'linux'
  properties: {
    reserved: true // Required for Linux
  }
}

// ========================================
// App Service (Web App)
// ========================================
// Hosts the containerized .NET application
resource appService 'Microsoft.Web/sites@2023-12-01' = {
  name: !empty(appServiceName) ? appServiceName : 'azapp${resourceToken}'
  location: location
  tags: union(tags, {
    'azd-service-name': 'web' // Required by AZD
  })
  kind: 'app,linux,container'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|mcr.microsoft.com/appsvc/staticsite:latest' // Placeholder image
      alwaysOn: false
      ftpsState: 'Disabled'
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.properties.ConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistry.properties.loginServer}'
        }
        {
          name: 'DOCKER_ENABLE_CI'
          value: 'true'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
      ]
      cors: {
        allowedOrigins: [
          'https://portal.azure.com'
        ]
        supportCredentials: false
      }
    }
  }
}

// ========================================
// Diagnostic Settings for App Service
// ========================================
// Send logs and metrics to Log Analytics
resource appServiceDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diagnostics'
  scope: appService
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// ========================================
// RBAC: Grant App Service AcrPull access to Container Registry
// ========================================
// Allows App Service to pull images from ACR without passwords
var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistry.id, managedIdentity.id, acrPullRoleDefinitionId)
  scope: containerRegistry
  properties: {
    roleDefinitionId: acrPullRoleDefinitionId
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// ========================================
// Outputs
// ========================================
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output RESOURCE_GROUP_ID string = resourceGroup().id

output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.properties.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.name

output SERVICE_WEB_IDENTITY_PRINCIPAL_ID string = managedIdentity.properties.principalId
output SERVICE_WEB_NAME string = appService.name
output SERVICE_WEB_URI string = 'https://${appService.properties.defaultHostName}'

output APPLICATIONINSIGHTS_CONNECTION_STRING string = applicationInsights.properties.ConnectionString
output APPLICATIONINSIGHTS_NAME string = applicationInsights.name
