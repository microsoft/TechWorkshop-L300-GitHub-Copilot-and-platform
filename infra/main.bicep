targetScope = 'resourceGroup'

@description('Environment name (dev, staging, prod)')
@maxLength(10)
param environmentName string = 'dev'

@description('Application name')
@maxLength(20)
param applicationName string = 'zavastore'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Docker image name')
param dockerImageName string = 'simplestore'

@description('Docker image tag')
param dockerImageTag string = 'latest'

// Generate unique resource names
var uniqueSuffix = uniqueString(resourceGroup().id)
var acrName = 'acr${applicationName}${uniqueSuffix}'
var logAnalyticsName = 'log-${applicationName}-${environmentName}-${uniqueSuffix}'
var appInsightsName = 'appi-${applicationName}-${environmentName}-${uniqueSuffix}'
var appServicePlanName = 'asp-${applicationName}-${environmentName}-${uniqueSuffix}'
var appServiceName = 'app-${applicationName}-${environmentName}-${uniqueSuffix}'

// Azure Container Registry
module acr 'modules/acr.bicep' = {
  name: 'acrDeployment'
  params: {
    acrName: acrName
    location: location
    sku: 'Basic'
    adminUserEnabled: true
  }
}

// Log Analytics Workspace
module logAnalytics 'modules/logAnalytics.bicep' = {
  name: 'logAnalyticsDeployment'
  params: {
    workspaceName: logAnalyticsName
    location: location
    sku: 'PerGB2018'
    retentionInDays: 30
  }
}

// Application Insights
module appInsights 'modules/appInsights.bicep' = {
  name: 'appInsightsDeployment'
  params: {
    appInsightsName: appInsightsName
    location: location
    workspaceId: logAnalytics.outputs.workspaceId
    applicationType: 'web'
  }
}

// App Service Plan
module appServicePlan 'modules/appServicePlan.bicep' = {
  name: 'appServicePlanDeployment'
  params: {
    appServicePlanName: appServicePlanName
    location: location
    sku: 'P1v2'
  }
}

// App Service
module appService 'modules/appService.bicep' = {
  name: 'appServiceDeployment'
  params: {
    appServiceName: appServiceName
    location: location
    appServicePlanId: appServicePlan.outputs.appServicePlanId
    acrLoginServer: acr.outputs.acrLoginServer
    dockerImageName: dockerImageName
    dockerImageTag: dockerImageTag
    appInsightsConnectionString: appInsights.outputs.connectionString
    acrId: acr.outputs.acrId
    acrName: acr.outputs.acrName
  }
}

// Outputs
output acrLoginServer string = acr.outputs.acrLoginServer
output acrName string = acr.outputs.acrName
output appServiceUrl string = appService.outputs.appServiceUrl
output appServiceName string = appService.outputs.appServiceName
output appInsightsInstrumentationKey string = appInsights.outputs.instrumentationKey
output appInsightsConnectionString string = appInsights.outputs.connectionString
output resourceGroupName string = resourceGroup().name
output location string = location
