targetScope = 'subscription'

// ============================================================================
// PARAMETERS
// ============================================================================

@description('Name of the environment (e.g., dev, staging, prod)')
param environmentName string

@description('Primary location for all resources')
@allowed(['westus3'])
param location string = 'westus3'

@description('Tags to apply to all resources')
param tags object = {}

// ============================================================================
// VARIABLES
// ============================================================================

// Generate unique suffix for resource names
var resourceSuffix = take(uniqueString(subscription().id, environmentName, location), 6)
var resourceGroupName = 'rg-${environmentName}-${resourceSuffix}'

// Combine default tags with provided tags
var defaultTags = {
  'azd-env-name': environmentName
  environment: environmentName
  project: 'ZavaStorefront'
}
var allTags = union(defaultTags, tags)

// ============================================================================
// RESOURCE GROUP
// ============================================================================

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: allTags
}

// ============================================================================
// MONITORING (Deploy first as other resources depend on it)
// ============================================================================

module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    name: 'zavastorefront'
    location: location
    tags: allTags
  }
}

// ============================================================================
// CONTAINER REGISTRY
// ============================================================================

module containerRegistry 'modules/container-registry.bicep' = {
  name: 'container-registry'
  scope: rg
  params: {
    name: 'zavastorefront'
    location: location
    tags: allTags
  }
}

// ============================================================================
// APP SERVICE
// ============================================================================

module appService 'modules/app-service.bicep' = {
  name: 'app-service'
  scope: rg
  params: {
    name: 'zavastorefront'
    location: location
    tags: union(allTags, {
      'azd-service-name': 'web'
    })
    containerRegistryName: containerRegistry.outputs.name
    applicationInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
    applicationInsightsInstrumentationKey: monitoring.outputs.applicationInsightsInstrumentationKey
  }
}

// ============================================================================
// AI FOUNDRY (Azure AI Services)
// ============================================================================

module aiFoundry 'modules/ai-foundry.bicep' = {
  name: 'ai-foundry'
  scope: rg
  params: {
    name: 'zavastorefront'
    location: location
    tags: allTags
    appServicePrincipalId: appService.outputs.principalId
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

@description('The name of the resource group')
output AZURE_RESOURCE_GROUP string = rg.name

@description('The location of the resource group')
output AZURE_LOCATION string = location

@description('The name of the App Service')
output AZURE_APP_SERVICE_NAME string = appService.outputs.name

@description('The default hostname of the App Service')
output AZURE_APP_SERVICE_URL string = appService.outputs.uri

@description('The name of the Container Registry')
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name

@description('The login server of the Container Registry')
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer

@description('The name of the Application Insights instance')
output AZURE_APPLICATION_INSIGHTS_NAME string = monitoring.outputs.applicationInsightsName

@description('The name of the AI Services account')
output AZURE_AI_SERVICES_NAME string = aiFoundry.outputs.name

@description('The endpoint of the AI Services account')
output AZURE_AI_ENDPOINT string = aiFoundry.outputs.endpoint
