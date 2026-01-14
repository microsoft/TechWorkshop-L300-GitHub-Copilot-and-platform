
// Main Bicep template for ZavaStorefront Dev Environment
param location string = 'westus3'
param environment string = 'dev'
param webAppName string = 'zavastorefront-webapp-dev'

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

@description('The container image name (e.g., myrepo/myimage)')
param imageName string = 'zavastorefront'
@description('The container image tag (e.g., latest)')
param imageTag string = 'latest'

module webApp 'modules/webApp.bicep' = {
  name: 'webAppModule'
  params: {
    webAppName: webAppName
    location: location
    appServicePlanId: appServicePlan.outputs.planId
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
module logAnalytics 'modules/logAnalytics.bicep' = {
  name: 'logAnalyticsModule'
  params: {
    location: location
    environment: environment
  }
}
