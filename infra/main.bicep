@description('Location for all resources')
param location string = 'westus3'
@description('Prefix for resource names')
param prefix string = 'zavastoredev'

param acrName string = '${prefix}acr'
param appServicePlanName string = '${prefix}-plan'
param webAppName string = '${prefix}-web'
param logWorkspaceName string = '${prefix}-law'
param appInsightsName string = '${prefix}-appi'
param keyVaultName string = '${prefix}-kv'

module acr './modules/acr.bicep' = {
  name: 'acr'
  params: {
    name: acrName
    location: location
    sku: 'Standard'
  }
}

module logAnalytics './modules/logAnalytics.bicep' = {
  name: 'logAnalytics'
  params: {
    name: logWorkspaceName
    location: location
  }
}

module appInsights './modules/appInsights.bicep' = {
  name: 'appInsights'
  params: {
    name: appInsightsName
    location: location
    logWorkspaceId: logAnalytics.outputs.workspaceResourceId
  }
}

module appServicePlan './modules/appServicePlan.bicep' = {
  name: 'appServicePlan'
  params: {
    name: appServicePlanName
    location: location
    skuName: 'B1'
    skuTier: 'Basic'
  }
}

module webApp './modules/webApp.bicep' = {
  name: 'webApp'
  params: {
    name: webAppName
    location: location
    serverFarmId: appServicePlan.outputs.serverFarmId
  }
}

module keyVault './modules/keyVault.bicep' = {
  name: 'keyVault'
  params: {
    name: keyVaultName
    location: location
  }
}

output webAppUrl string = webApp.outputs.defaultHostname
output acrLoginServer string = acr.outputs.loginServer
output appInsightsInstrumentationKey string = appInsights.outputs.instrumentationKey
output SERVICE_WEB_RESOURCE_ID string = webApp.outputs.resourceId
output SERVICE_WEB_IDENTITY_PRINCIPAL_ID string = webApp.outputs.principalId
