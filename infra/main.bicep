targetScope = 'resourceGroup'

param location string = resourceGroup().location
param environmentName string
param resourceGroupName string = resourceGroup().name
param projectName string = 'zavastorefrontdev'
param containerImage string = 'nginx:latest'

// Resource naming
var acrName = replace('${projectName}acr${environmentName}', '-', '')
var appServicePlanName = 'plan-${projectName}-${environmentName}'
var webAppName = 'app-${projectName}-${environmentName}'
var logAnalyticsWorkspaceName = 'law-${projectName}-${environmentName}'

// Deploy Log Analytics Workspace
module logAnalytics './modules/logAnalytics.bicep' = {
  name: 'logAnalytics'
  params: {
    location: location
    environmentName: environmentName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
}

// Deploy Container Registry
module acr './modules/acr.bicep' = {
  name: 'acr'
  params: {
    location: location
    environmentName: environmentName
    acrName: acrName
  }
}

// Deploy App Service Plan and Web App
module appService './modules/appService.bicep' = {
  name: 'appService'
  params: {
    location: location
    environmentName: environmentName
    appServicePlanName: appServicePlanName
    webAppName: webAppName
    acrLoginServer: acr.outputs.acrLoginServer
    acrName: acrName
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
    containerImage: containerImage
  }
}

// Outputs
output acrLoginServer string = acr.outputs.acrLoginServer
output acrName string = acr.outputs.acrName
output acrId string = acr.outputs.acrId
output webAppUrl string = appService.outputs.webAppUrl
output webAppName string = appService.outputs.webAppName
output webAppId string = appService.outputs.webAppId
output webAppPrincipalId string = appService.outputs.webAppPrincipalId
output appServicePlanId string = appService.outputs.appServicePlanId
output logAnalyticsWorkspaceId string = logAnalytics.outputs.logAnalyticsWorkspaceId
output appInsightsInstrumentationKey string = appService.outputs.appInsightsInstrumentationKey
