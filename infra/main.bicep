targetScope = 'resourceGroup'

@description('AZD environment name.')
param environmentName string

@description('Primary deployment region.')
param location string

@description('AZD service name tag for the web app.')
param serviceName string = 'zavastorefront-web'

@description('Container image repository name inside ACR.')
param containerImageName string = 'zavastorefront'

@description('Container image tag used by App Service.')
param containerImageTag string = 'latest'

@description('Allowed CORS origins for the web app.')
param allowedCorsOrigins array = [
  'https://portal.azure.com'
]

var resourceToken = uniqueString(subscription().id, resourceGroup().id, location, environmentName)

var identityName = 'azid${resourceToken}'
var acrName = 'azacr${resourceToken}'
var logAnalyticsName = 'azla${resourceToken}'
var appInsightsName = 'azap${resourceToken}'
var planName = 'azasp${resourceToken}'
var webAppName = 'azweb${resourceToken}'
var foundryName = 'azai${resourceToken}'

module identity 'modules/identity.bicep' = {
  name: 'identity'
  params: {
    name: identityName
    location: location
  }
}

module acr 'modules/acr.bicep' = {
  name: 'acr'
  params: {
    name: acrName
    location: location
  }
}

module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    location: location
    logAnalyticsWorkspaceName: logAnalyticsName
    appInsightsName: appInsightsName
  }
}

module appServicePlan 'modules/appservice-plan.bicep' = {
  name: 'appServicePlan'
  params: {
    name: planName
    location: location
  }
}

module webApp 'modules/webapp-linux-container.bicep' = {
  name: 'webApp'
  params: {
    name: webAppName
    location: location
    appServicePlanId: appServicePlan.outputs.id
    userAssignedIdentityResourceId: identity.outputs.id
    userAssignedIdentityClientId: identity.outputs.clientId
    appInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    serviceName: serviceName
    acrLoginServer: acr.outputs.loginServer
    containerImageName: containerImageName
    containerImageTag: containerImageTag
    allowedCorsOrigins: allowedCorsOrigins
  }
}

module acrPull 'modules/rbac-acr-pull.bicep' = {
  name: 'acrPull'
  params: {
    principalId: identity.outputs.principalId
    acrResourceId: acr.outputs.id
  }
}

module foundry 'modules/foundry.bicep' = {
  name: 'foundry'
  params: {
    name: foundryName
    location: location
  }
}

output RESOURCE_GROUP_ID string = resourceGroup().id
output WEB_APP_NAME string = webAppName
output ACR_NAME string = acrName
output APP_INSIGHTS_NAME string = appInsightsName
output FOUNDRY_ENDPOINT string = foundry.outputs.endpoint
