targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment (e.g., dev, test, prod)')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string = 'westus3'

@description('Unique token for resource naming')
param resourceToken string = toLower(uniqueString(subscription().id, environmentName, location))

@description('Tags to apply to all resources')
param tags object = {
  environment: environmentName
  'azd-env-name': environmentName
}

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-${environmentName}-${resourceToken}'
  location: location
  tags: tags
}

// Log Analytics Workspace
module logAnalytics './modules/logAnalytics.bicep' = {
  scope: rg
  params: {
    name: 'log-${resourceToken}'
    location: location
    tags: tags
  }
}

// Application Insights
module applicationInsights './modules/applicationInsights.bicep' = {
  scope: rg
  params: {
    name: 'appi-${resourceToken}'
    location: location
    tags: tags
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
  }
}

// Azure Container Registry
module containerRegistry './modules/containerRegistry.bicep' = {
  scope: rg
  params: {
    name: 'cr${resourceToken}'
    location: location
    tags: tags
  }
}

// App Service Plan (Linux)
module appServicePlan './modules/appServicePlan.bicep' = {
  scope: rg
  params: {
    name: 'asp-${resourceToken}'
    location: location
    tags: tags
    sku: {
      name: 'F1'
      tier: 'Free'
    }
    kind: 'linux'
    reserved: true
  }
}

// App Service (Web App)
module appService './modules/appService.bicep' = {
  scope: rg
  params: {
    name: 'app-${resourceToken}'
    location: location
    tags: union(tags, {
      'azd-service-name': 'web'
    })
    appServicePlanId: appServicePlan.outputs.id
    containerRegistryName: containerRegistry.outputs.name
    applicationInsightsConnectionString: applicationInsights.outputs.connectionString
    applicationInsightsInstrumentationKey: applicationInsights.outputs.instrumentationKey
  }
}

// Storage Account for AI Foundry
module storageAccount './modules/storageAccount.bicep' = {
  scope: rg
  params: {
    name: 'st${resourceToken}'
    location: location
    tags: tags
  }
}

// Key Vault for AI Foundry
module keyVault './modules/keyVault.bicep' = {
  scope: rg
  params: {
    name: 'kv-${resourceToken}'
    location: location
    tags: tags
  }
}

// AI Foundry Hub
module aiHub './modules/aiHub.bicep' = {
  scope: rg
  params: {
    name: 'mlw-hub-${resourceToken}'
    location: location
    tags: tags
    storageAccountId: storageAccount.outputs.id
    keyVaultId: keyVault.outputs.id
    applicationInsightsId: applicationInsights.outputs.id
  }
}

// AI Foundry Project
module aiProject './modules/aiProject.bicep' = {
  scope: rg
  params: {
    name: 'mlw-proj-${resourceToken}'
    location: location
    tags: tags
    aiHubId: aiHub.outputs.id
  }
}

// Assign ACR Pull role to App Service managed identity
module acrRoleAssignment './modules/acrRoleAssignment.bicep' = {
  scope: rg
  params: {
    containerRegistryName: containerRegistry.outputs.name
    principalId: appService.outputs.principalId
  }
}

// Outputs
output AZURE_RESOURCE_GROUP string = rg.name
output AZURE_LOCATION string = location
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name
output APP_SERVICE_NAME string = appService.outputs.name
output APP_SERVICE_URL string = appService.outputs.url
output APPLICATION_INSIGHTS_CONNECTION_STRING string = applicationInsights.outputs.connectionString
output AI_HUB_NAME string = aiHub.outputs.name
output AI_PROJECT_NAME string = aiProject.outputs.name
