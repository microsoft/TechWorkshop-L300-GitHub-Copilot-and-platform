// Main Bicep template for ZavaStorefront dev environment
param environment string = 'dev'
param location string = 'eastus'

module acr 'modules/acr.bicep' = {
  name: 'acrModule'
  params: {
    location: location
  }
}

module appServicePlan 'modules/appServicePlan.bicep' = {
  name: 'appServicePlanModule'
  params: {
    location: location
    environment: environment
  }
}

module webApp 'modules/webApp.bicep' = {
  name: 'webAppModule'
  params: {
    serviceName: 'storefront'
    location: location
    appServicePlanId: appServicePlan.outputs.planId
    appInsightsConnectionString: appInsights.outputs.connectionString
    foundryEndpoint: foundry.outputs.foundryEndpoint
  }
}

module appInsights 'modules/appInsights.bicep' = {
  name: 'appInsightsModule'
  params: {
    location: location
    environment: environment
  }
}

module foundry 'modules/foundry.bicep' = {
  name: 'foundryModule'
  params: {
    location: location
    environment: environment
  }
}

module roleAssignment 'modules/roleAssignment.bicep' = {
  name: 'roleAssignmentModule'
  params: {
    principalId: webApp.outputs.principalId
    acrName: acr.outputs.acrName
  }
}

output webAppName string = webApp.outputs.webAppName
output webAppHostname string = webApp.outputs.webAppHostname
output webAppUrl string = webApp.outputs.webAppUrl
output containerRegistryName string = acr.outputs.acrName
output containerRegistryLoginServer string = acr.outputs.acrLoginServer

// Convenience outputs for tooling expecting these names
output AZURE_CONTAINER_REGISTRY string = acr.outputs.acrName
output AZURE_CONTAINER_REGISTRY_LOGIN_SERVER string = acr.outputs.acrLoginServer
