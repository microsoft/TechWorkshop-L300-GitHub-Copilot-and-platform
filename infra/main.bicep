targetScope = 'resourceGroup'

@description('AZD environment name parameter.')
param environmentName string

@description('Azure region for all resources.')
param location string = resourceGroup().location

@description('Service name in azure.yaml for azd-service-name tagging.')
param serviceName string = 'storefront'

@description('Container image name/tag in ACR.')
param containerImageName string = 'zavastorefront:latest'

var resourceToken = uniqueString(subscription().id, resourceGroup().id, location, environmentName)

var logAnalyticsName = 'azlaw${resourceToken}'
var appInsightsName = 'azaii${resourceToken}'
var acrName = 'azacr${resourceToken}'
var managedIdentityName = 'azid${resourceToken}'
var appServicePlanName = 'azasp${resourceToken}'
var webAppName = 'azapp${resourceToken}'
var foundryName = 'azaif${resourceToken}'

module logAnalytics './modules/logAnalytics.bicep' = {
  name: 'logAnalytics'
  params: {
    resourceName: logAnalyticsName
    location: location
  }
}

module appInsights './modules/appInsights.bicep' = {
  name: 'appInsights'
  params: {
    resourceName: appInsightsName
    location: location
    workspaceResourceId: logAnalytics.outputs.id
  }
}

module acr './modules/acr.bicep' = {
  name: 'acr'
  params: {
    resourceName: acrName
    location: location
  }
}

module managedIdentity './modules/managedIdentity.bicep' = {
  name: 'managedIdentity'
  params: {
    resourceName: managedIdentityName
    location: location
  }
}

module appServicePlan './modules/appServicePlan.bicep' = {
  name: 'appServicePlan'
  params: {
    resourceName: appServicePlanName
    location: location
  }
}

module webApp './modules/webApp.bicep' = {
  name: 'webApp'
  params: {
    resourceName: webAppName
    location: location
    appServicePlanId: appServicePlan.outputs.id
    userAssignedIdentityResourceId: managedIdentity.outputs.id
    userAssignedIdentityClientId: managedIdentity.outputs.clientId
    appInsightsConnectionString: appInsights.outputs.connectionString
    containerImage: '${acr.outputs.loginServer}/${containerImageName}'
    serviceName: serviceName
  }
}

module acrPullRole './modules/roleAssignmentAcrPull.bicep' = {
  name: 'acrPullRole'
  params: {
    registryName: acrName
    principalId: managedIdentity.outputs.principalId
  }
}

module aiFoundry './modules/aiFoundry.bicep' = {
  name: 'aiFoundry'
  params: {
    resourceName: foundryName
    location: location
  }
}

output RESOURCE_GROUP_ID string = resourceGroup().id
output ACR_LOGIN_SERVER string = acr.outputs.loginServer
output WEB_APP_NAME string = webAppName
output WEB_APP_URL string = 'https://${webAppName}.azurewebsites.net'
output APPLICATION_INSIGHTS_CONNECTION_STRING string = appInsights.outputs.connectionString
output AZURE_OPENAI_ENDPOINT string = aiFoundry.outputs.endpoint
