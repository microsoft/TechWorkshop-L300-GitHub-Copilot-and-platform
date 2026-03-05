targetScope = 'resourceGroup'

@description('Environment name (e.g. dev, staging, prod)')
param environmentName string

@description('Azure region for all resources')
param location string = 'westus3'

var tags = {
  environment: environmentName
  project: 'zava-storefront'
  'azd-env-name': environmentName
}

module identity 'modules/identity.bicep' = {
  params: {
    location: location
    tags: tags
  }
}

module registry 'modules/registry.bicep' = {
  params: {
    location: location
    tags: tags
    uamiPrincipalId: identity.outputs.identityPrincipalId
  }
}

module monitoring 'modules/monitoring.bicep' = {
  params: {
    location: location
    tags: tags
  }
}

module appservice 'modules/appservice.bicep' = {
  params: {
    location: location
    tags: tags
    uamiId: identity.outputs.identityId
    uamiClientId: identity.outputs.identityClientId
    registryLoginServer: registry.outputs.registryLoginServer
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString
    logAnalyticsCustomerId: monitoring.outputs.logAnalyticsCustomerId
    logAnalyticsKey: monitoring.outputs.logAnalyticsKey
  }
}

module aiservices 'modules/aiservices.bicep' = {
  params: {
    location: location
    tags: tags
  }
}

// AZD reads these outputs as environment variables during hooks and deploy
output AZURE_CONTAINER_REGISTRY_NAME string = registry.outputs.registryName
output AZURE_CONTAINER_REGISTRY_LOGIN_SERVER string = registry.outputs.registryLoginServer
output AZURE_CONTAINER_APP_NAME string = appservice.outputs.containerAppName
output AZURE_CONTAINER_APP_URL string = 'https://${appservice.outputs.containerAppHostName}'
output AZURE_AI_SERVICES_ENDPOINT string = aiservices.outputs.aiServicesEndpoint
