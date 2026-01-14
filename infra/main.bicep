// Main Bicep template for ZavaStorefront dev environment
param env string = 'dev'
param location string = 'westus3'
param acrSku string = 'Basic'
param planSkuName string = 'B1'
param planSkuTier string = 'Basic'
param webAppImageName string = 'zavastorefront:latest'
param foundrySku string = 'S0'

var acrName = 'crn${uniqueString(resourceGroup().id, env)}'
var envName = 'cae${uniqueString(resourceGroup().id, env)}'
var containerAppName = 'app${uniqueString(resourceGroup().id, env)}'
var logAnalyticsName = 'log-${uniqueString(resourceGroup().id, env)}'
var appInsightsName = 'appi-${uniqueString(resourceGroup().id, env)}'
var foundryName = 'aif-${uniqueString(resourceGroup().id, env)}'

module acr 'modules/acr.bicep' = {
  name: 'acr'
  params: {
    name: acrName
    location: location
    sku: acrSku
  }
}

module logAnalytics 'modules/loganalytics.bicep' = {
  name: 'logAnalytics'
  params: {
    name: logAnalyticsName
    location: location
  }
}

module containerAppEnv 'modules/appserviceplan.bicep' = {
  name: 'containerAppEnv'
  params: {
    name: envName
    location: location
    logAnalyticsCustomerId: logAnalytics.outputs.logAnalyticsCustomerId
    logAnalyticsSharedKey: logAnalytics.outputs.logAnalyticsSharedKey
  }
}

// module appInsights 'modules/appinsights.bicep' = {
//   name: 'appInsights'
//   params: {
//     name: appInsightsName
//     location: location
//   }
// }

module foundry 'modules/foundry.bicep' = {
  name: 'foundry'
  params: {
    name: foundryName
    location: location
    sku: foundrySku
  }
}

module containerApp 'modules/webApp.bicep' = {
  name: 'containerApp'
  params: {
    name: containerAppName
    location: location
    environmentId: containerAppEnv.outputs.environmentId
    acrLoginServer: '${acr.outputs.acrName}.azurecr.io'
    acrName: acr.outputs.acrName
  }
}

module roleAssignment 'modules/roleassignment.bicep' = {
  name: 'roleAssignment'
  params: {
    principalId: containerApp.outputs.containerAppIdentityPrincipalId
    acrName: acr.outputs.acrName
  }
}

// Outputs for azd
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = '${acr.outputs.acrName}.azurecr.io'
output AZURE_CONTAINER_REGISTRY_NAME string = acr.outputs.acrName
output CONTAINER_APP_NAME string = containerApp.outputs.containerAppName
output CONTAINER_APP_URL string = 'https://${containerApp.outputs.containerAppFqdn}'
