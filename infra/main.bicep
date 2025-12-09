// =============================================================================
// ZavaStorefront Infrastructure - Main Bicep Template
// Deploys Azure App Service with ACR, AI Services, and Application Insights
// =============================================================================

targetScope = 'resourceGroup'

// -----------------------------------------------------------------------------
// Parameters
// -----------------------------------------------------------------------------

@description('The name of the application')
param appName string = 'zavastore'

@description('The environment (dev, staging, prod)')
@allowed([
  'dev'
  'staging'
  'prod'
])
param environment string = 'dev'

@description('The Azure region for all resources')
param location string = resourceGroup().location

@description('The SKU of the App Service Plan')
@allowed([
  'F1'
  'B1'
  'B2'
  'S1'
  'S2'
  'P1v2'
  'P2v2'
])
param appServicePlanSku string = 'B1'

@description('The SKU of the Azure Container Registry')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param acrSku string = 'Basic'

@description('Tags to apply to all resources')
param tags object = {
  Application: 'ZavaStorefront'
  Environment: environment
  ManagedBy: 'Bicep'
}

// -----------------------------------------------------------------------------
// Variables
// -----------------------------------------------------------------------------

var uniqueSuffix = uniqueString(resourceGroup().id)
var resourcePrefix = '${appName}${environment}'
var resourcePrefixDash = '${appName}-${environment}'
var appServicePlanName = 'asp-${resourcePrefixDash}'
var webAppName = 'app-${resourcePrefixDash}-${uniqueSuffix}'
var logAnalyticsWorkspaceName = 'law-${resourcePrefixDash}'
var appInsightsName = 'ai-${resourcePrefixDash}'
var containerRegistryName = 'acr${resourcePrefix}${uniqueSuffix}' // ACR names must be alphanumeric
var aiServicesName = 'ais-${resourcePrefixDash}-${uniqueSuffix}'

// AcrPull role definition ID
var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

// -----------------------------------------------------------------------------
// Log Analytics Workspace (using Azure Verified Module)
// -----------------------------------------------------------------------------

module logAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.9.1' = {
  name: 'logAnalyticsWorkspaceDeployment'
  params: {
    name: logAnalyticsWorkspaceName
    location: location
    tags: tags
    skuName: 'PerGB2018'
    dataRetention: 30
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// -----------------------------------------------------------------------------
// Application Insights (using Azure Verified Module)
// -----------------------------------------------------------------------------

module appInsights 'br/public:avm/res/insights/component:0.4.2' = {
  name: 'appInsightsDeployment'
  params: {
    name: appInsightsName
    location: location
    tags: tags
    workspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
    applicationType: 'web'
    retentionInDays: 90
    disableIpMasking: false
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// -----------------------------------------------------------------------------
// App Service Plan
// -----------------------------------------------------------------------------

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
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

// -----------------------------------------------------------------------------
// Azure Container Registry (using Azure Verified Module)
// -----------------------------------------------------------------------------

module containerRegistry 'br/public:avm/res/container-registry/registry:0.8.0' = {
  name: 'containerRegistryDeployment'
  params: {
    name: containerRegistryName
    location: location
    tags: tags
    acrSku: acrSku
    acrAdminUserEnabled: false // Use managed identity instead
    publicNetworkAccess: 'Enabled'
  }
}

// -----------------------------------------------------------------------------
// Azure AI Services (for GPT-4 and Phi models)
// -----------------------------------------------------------------------------

module aiServices 'br/public:avm/res/cognitive-services/account:0.10.1' = {
  name: 'aiServicesDeployment'
  params: {
    name: aiServicesName
    kind: 'AIServices'
    location: location
    tags: tags
    customSubDomainName: aiServicesName
    sku: 'S0'
    publicNetworkAccess: 'Enabled'
    managedIdentities: {
      systemAssigned: true
    }
    deployments: [
      {
        name: 'gpt-4o'
        model: {
          format: 'OpenAI'
          name: 'gpt-4o'
          version: '2024-05-13'
        }
        sku: {
          name: 'GlobalStandard'
          capacity: 10
        }
      }
    ]
  }
}

// -----------------------------------------------------------------------------
// Web App (Web App for Containers)
// -----------------------------------------------------------------------------

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  tags: tags
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerRegistry.outputs.loginServer}/${appName}:latest'
      acrUseManagedIdentityCreds: true // Use managed identity to pull from ACR
      alwaysOn: appServicePlanSku != 'F1' // Always On not supported on Free tier
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.outputs.connectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'Recommended'
        }
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: environment == 'prod' ? 'Production' : 'Development'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistry.outputs.loginServer}'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
      ]
    }
  }
}

// -----------------------------------------------------------------------------
// AcrPull Role Assignment (Web App -> ACR)
// Reference the deployed ACR to scope the role assignment
// -----------------------------------------------------------------------------

resource existingAcr 'Microsoft.ContainerRegistry/registries@2023-06-01-preview' existing = {
  name: containerRegistryName
  dependsOn: [
    containerRegistry
  ]
}

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(existingAcr.id, webApp.id, acrPullRoleDefinitionId)
  scope: existingAcr
  properties: {
    roleDefinitionId: acrPullRoleDefinitionId
    principalId: webApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// -----------------------------------------------------------------------------
// Diagnostic Settings for Web App
// -----------------------------------------------------------------------------

resource webAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'webAppDiagnostics'
  scope: webApp
  properties: {
    workspaceId: logAnalyticsWorkspace.outputs.resourceId
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'AppServicePlatformLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}

// -----------------------------------------------------------------------------
// Outputs
// -----------------------------------------------------------------------------

@description('The name of the deployed Web App')
output webAppName string = webApp.name

@description('The default hostname of the Web App')
output webAppHostname string = webApp.properties.defaultHostName

@description('The URL of the deployed Web App')
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'

@description('The resource ID of the Web App')
output webAppResourceId string = webApp.id

@description('The principal ID of the Web App managed identity')
output webAppPrincipalId string = webApp.identity.principalId

@description('The name of the App Service Plan')
output appServicePlanName string = appServicePlan.name

@description('The resource ID of the Log Analytics Workspace')
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.outputs.resourceId

@description('The name of the Application Insights instance')
output appInsightsName string = appInsights.outputs.name

@description('The Application Insights instrumentation key')
output appInsightsInstrumentationKey string = appInsights.outputs.instrumentationKey

@description('The Application Insights connection string')
output appInsightsConnectionString string = appInsights.outputs.connectionString

@description('The name of the Azure Container Registry')
output containerRegistryName string = containerRegistry.outputs.name

@description('The login server of the Azure Container Registry')
output containerRegistryLoginServer string = containerRegistry.outputs.loginServer

@description('The resource ID of the Azure Container Registry')
output containerRegistryResourceId string = containerRegistry.outputs.resourceId

@description('The name of the Azure AI Services account')
output aiServicesName string = aiServices.outputs.name

@description('The endpoint of the Azure AI Services account')
output aiServicesEndpoint string = aiServices.outputs.endpoint

@description('The resource ID of the Azure AI Services account')
output aiServicesResourceId string = aiServices.outputs.resourceId
