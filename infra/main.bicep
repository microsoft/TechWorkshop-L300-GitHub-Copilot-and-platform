// Main Bicep template for ZavaStorefront dev environment
param env string = 'dev'
param location string = 'westus3'
param acrSku string = 'Basic'
param planSkuName string = 'B1'
param planSkuTier string = 'Basic'
param webAppImageName string = 'zavastorefront:latest'
param foundrySku string = 'Standard'

var acrName = 'crn${uniqueString(resourceGroup().id, env)}'
var planName = 'asp${uniqueString(resourceGroup().id, env)}'
var webAppName = 'app${uniqueString(resourceGroup().id, env)}'
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

module plan 'modules/appserviceplan.bicep' = {
  name: 'plan'
  params: {
    name: planName
    location: location
    skuName: planSkuName
    skuTier: planSkuTier
  }
}

module appInsights 'modules/appinsights.bicep' = {
  name: 'appInsights'
  params: {
    name: appInsightsName
    location: location
  }
}

module foundry 'modules/foundry.bicep' = {
  name: 'foundry'
  params: {
    name: foundryName
    location: location
    sku: foundrySku
  }
}

module webApp 'modules/webApp.bicep' = {
  name: 'webApp'
  params: {
    name: webAppName
    location: location
    planId: plan.outputs.planId
    acrLoginServer: acr.outputs.acrName + '.azurecr.io'
    imageName: webAppImageName
    managedIdentityId: '' // Will be set by system-assigned identity
    appInsightsKey: appInsights.outputs.appInsightsKey
  }
}

module roleAssignment 'modules/roleassignment.bicep' = {
  name: 'roleAssignment'
  params: {
    principalId: webApp.outputs.webAppIdentityPrincipalId
    acrId: acr.outputs.acrId
  }
}
