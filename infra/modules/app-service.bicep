targetScope = 'resourceGroup'

// ============================================================================
// PARAMETERS
// ============================================================================

@description('Base name for all resources')
param name string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Tags to apply to all resources')
param tags object = {}

@description('The name of the Container Registry for pulling images')
param containerRegistryName string

@description('Application Insights connection string for telemetry')
@secure()
param applicationInsightsConnectionString string

@description('Application Insights instrumentation key')
@secure()
param applicationInsightsInstrumentationKey string

@description('The SKU of the App Service Plan')
@allowed(['B1', 'B2', 'B3', 'S1', 'S2', 'S3', 'P1v2', 'P2v2', 'P3v2'])
param appServicePlanSku string = 'B1'

// ============================================================================
// VARIABLES
// ============================================================================

var resourceSuffix = take(uniqueString(subscription().id, resourceGroup().name, name), 6)
var appServicePlanName = 'asp-${name}-${resourceSuffix}'
var appServiceName = 'app-${name}-${resourceSuffix}'

// Remove azd-service-name tag from App Service Plan (only App Service should have it)
var appServicePlanTags = reduce(items(tags), {}, (cur, next) => next.key == 'azd-service-name' ? cur : union(cur, { '${next.key}': next.value }))

// ============================================================================
// APP SERVICE PLAN
// ============================================================================

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  tags: appServicePlanTags
  kind: 'linux'
  sku: {
    name: appServicePlanSku
  }
  properties: {
    reserved: true // Required for Linux
  }
}

// ============================================================================
// APP SERVICE
// ============================================================================

resource appService 'Microsoft.Web/sites@2023-12-01' = {
  name: appServiceName
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
      linuxFxVersion: 'DOTNETCORE|8.0'
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsightsConnectionString
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
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistryName}.azurecr.io'
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
    }
  }
}

// ============================================================================
// CONTAINER REGISTRY ROLE ASSIGNMENT (AcrPull)
// ============================================================================

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' existing = {
  name: containerRegistryName
}

// AcrPull role definition ID
var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistry.id, appService.id, acrPullRoleDefinitionId)
  scope: containerRegistry
  properties: {
    principalId: appService.identity.principalId
    roleDefinitionId: acrPullRoleDefinitionId
    principalType: 'ServicePrincipal'
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

@description('The name of the App Service')
output name string = appService.name

@description('The default hostname of the App Service')
output uri string = 'https://${appService.properties.defaultHostName}'

@description('The principal ID of the App Service managed identity')
output principalId string = appService.identity.principalId

@description('The resource ID of the App Service')
output resourceId string = appService.id
