targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment used for resource naming')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

// Tags that will be applied to all resources
var tags = {
  'azd-env-name': environmentName
  environment: 'dev'
}

// Organize resources in a single resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

// Container Registry
module containerRegistry 'core/registry.bicep' = {
  name: 'container-registry'
  scope: rg
  params: {
    name: 'cr${replace(environmentName, '-', '')}'
    location: location
    tags: tags
  }
}

// Application Insights for monitoring
module monitoring 'core/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    name: 'appi-${environmentName}'
    location: location
    tags: tags
  }
}

// App Service Plan (Linux)
module appServicePlan 'core/appserviceplan.bicep' = {
  name: 'app-service-plan'
  scope: rg
  params: {
    name: 'asp-${environmentName}'
    location: location
    tags: tags
    kind: 'linux'
    sku: {
      name: 'B1'
      tier: 'Basic'
      capacity: 1
    }
  }
}

// App Service (Web App)
module appService 'core/appservice.bicep' = {
  name: 'app-service'
  scope: rg
  params: {
    name: 'app-${environmentName}'
    location: location
    tags: tags
    appServicePlanId: appServicePlan.outputs.id
    containerRegistryName: containerRegistry.outputs.name
    applicationInsightsConnectionString: monitoring.outputs.connectionString
  }
}

// Azure AI Foundry (Cognitive Services)
module aiFoundry 'core/aifoundry.bicep' = {
  name: 'ai-foundry'
  scope: rg
  params: {
    name: 'cog-${environmentName}'
    location: location
    tags: tags
  }
}

// Outputs
output AZURE_LOCATION string = location
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name
output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.connectionString
output WEB_APP_NAME string = appService.outputs.name
output WEB_APP_URL string = appService.outputs.uri
output AI_FOUNDRY_ENDPOINT string = aiFoundry.outputs.endpoint
output AI_FOUNDRY_KEY string = aiFoundry.outputs.key
