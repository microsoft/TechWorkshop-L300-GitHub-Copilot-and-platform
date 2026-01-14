// Main Bicep template for ZavaStorefront infrastructure
targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment (e.g., dev, test, prod)')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string = 'swedencentral'

@description('Application name used for resource naming')
param appName string = 'zavastore'

@description('Id of the user or app to assign application roles')
param principalId string = ''

// Generate unique suffix for globally unique resources
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = {
  'azd-env-name': environmentName
  application: appName
  environment: environmentName
  SecurityControl: 'Ignore'
  CostControl: 'Ignore'
}

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${appName}-${environmentName}-${location}'
  location: location
  tags: tags
}

// Log Analytics Workspace
module logAnalytics './modules/log-analytics.bicep' = {
  name: 'log-analytics'
  scope: rg
  params: {
    name: 'law-${appName}-${environmentName}-${location}'
    location: location
    tags: tags
  }
}

// Application Insights
module appInsights './modules/app-insights.bicep' = {
  name: 'app-insights'
  scope: rg
  params: {
    name: 'appi-${appName}-${environmentName}-${location}'
    location: location
    tags: tags
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
  }
}

// Container Registry
module containerRegistry './modules/container-registry.bicep' = {
  name: 'container-registry'
  scope: rg
  params: {
    name: 'cr${appName}${resourceToken}'
    location: location
    tags: tags
  }
}

// App Service Plan
module appServicePlan './modules/app-service-plan.bicep' = {
  name: 'app-service-plan'
  scope: rg
  params: {
    name: 'asp-${appName}-${environmentName}-${location}'
    location: location
    tags: tags
    sku: {
      name: 'B1'
      tier: 'Basic'
    }
    kind: 'linux'
    reserved: true
  }
}

// Web App
module webApp './modules/web-app.bicep' = {
  name: 'web-app'
  scope: rg
  params: {
    name: 'app-${appName}-${environmentName}-${resourceToken}'
    location: location
    tags: tags
    appServicePlanId: appServicePlan.outputs.id
    containerRegistryName: containerRegistry.outputs.name
    appInsightsConnectionString: appInsights.outputs.connectionString
    appInsightsInstrumentationKey: appInsights.outputs.instrumentationKey
  }
}

// Role Assignment - Grant Web App AcrPull permissions on Container Registry
module roleAssignment './modules/role-assignment.bicep' = {
  name: 'role-assignment-acrpull'
  scope: rg
  params: {
    principalId: webApp.outputs.systemAssignedIdentityPrincipalId
    roleDefinitionId: '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull role
    containerRegistryName: containerRegistry.outputs.name
  }
}

// AI Hub (Microsoft Foundry)
module aiHub './modules/ai-hub.bicep' = {
  name: 'ai-hub'
  scope: rg
  params: {
    name: 'aih-${appName}-${environmentName}-${location}'
    location: location
    tags: tags
    appInsightsId: appInsights.outputs.id
  }
}

// Outputs
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP string = rg.name

output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name

output AZURE_APP_SERVICE_NAME string = webApp.outputs.name
output AZURE_APP_SERVICE_URL string = webApp.outputs.uri

output APPLICATIONINSIGHTS_CONNECTION_STRING string = appInsights.outputs.connectionString
output APPLICATIONINSIGHTS_NAME string = appInsights.outputs.name

output AI_HUB_NAME string = aiHub.outputs.name
output AI_HUB_ID string = aiHub.outputs.id
