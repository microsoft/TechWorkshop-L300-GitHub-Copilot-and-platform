// Main Bicep template for ZavaStorefront dev infra
// Orchestrates all modules
param resourceGroupName string
param location string = 'westus3'
param environment string = 'dev'
param acrSku string = 'Basic'
param appServicePlanSku string = 'B1'
param foundrySku string = 'dev'

module acr 'modules/acr.bicep' = {
  name: 'acrModule'
  params: {
    resourceGroupName: resourceGroupName
    location: location
    sku: acrSku
    environment: environment
  }
}

module appInsights 'modules/appinsights.bicep' = {
  name: 'appInsightsModule'
  params: {
    resourceGroupName: resourceGroupName
    location: location
    environment: environment
  }
}

module appServicePlan 'modules/appserviceplan.bicep' = {
  name: 'appServicePlanModule'
  params: {
    resourceGroupName: resourceGroupName
    location: location
    sku: appServicePlanSku
    environment: environment
  }
}

module webApp 'modules/webapp.bicep' = {
  name: 'webAppModule'
  params: {
    resourceGroupName: resourceGroupName
    location: location
    environment: environment
    appServicePlanId: appServicePlan.outputs.appServicePlanId
    acrLoginServer: acr.outputs.loginServer
    appInsightsInstrumentationKey: appInsights.outputs.instrumentationKey
    // managedIdentityPrincipalId parameter removed to fix circular reference
  }
}



module roleAssignment 'modules/roleassignment.bicep' = {
  name: 'roleAssignmentModule'
  params: {
    principalId: webApp.outputs.principalId
    acrResourceId: acr.outputs.acrResourceId
  }
}
