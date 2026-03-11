targetScope = 'resourceGroup'

@description('Environment name used in resource naming.')
param environmentName string = 'dev'

@description('Azure region for all resources.')
param location string = resourceGroup().location

@description('Short project name used in resource naming.')
param projectName string = 'zava'

@description('Container image repository name inside ACR.')
param imageName string = 'zavastorefront'

@description('Container image tag to deploy.')
param imageTag string = 'latest'

@description('App Service plan SKU.')
param appServiceSku string = 'B1'

@description('Container Registry SKU.')
param acrSku string = 'Basic'

@description('OpenAI account SKU.')
param aiSku string = 'S0'

@description('Tags to apply to all resources where supported.')
param tags object = {
  environment: environmentName
  workload: 'zavastorefront'
  managedBy: 'azd-bicep'
}

var suffix = toLower(uniqueString(subscription().id, resourceGroup().id, environmentName))
var acrName = 'acr${take(replace(suffix, '-', ''), 18)}'
var planName = 'asp-${projectName}-${environmentName}-${take(suffix, 6)}'
var webAppName = 'app-${projectName}-${environmentName}-${take(suffix, 6)}'
var logAnalyticsName = 'log-${projectName}-${environmentName}-${take(suffix, 6)}'
var appInsightsName = 'appi-${projectName}-${environmentName}-${take(suffix, 6)}'
var aiAccountName = 'aoai-${take(suffix, 10)}'

module acr './modules/acr.bicep' = {
  params: {
    name: acrName
    location: location
    sku: acrSku
    tags: tags
  }
}

module logAnalytics './modules/logAnalytics.bicep' = {
  params: {
    name: logAnalyticsName
    location: location
    tags: tags
  }
}

module appInsights './modules/appInsights.bicep' = {
  params: {
    name: appInsightsName
    location: location
    workspaceResourceId: logAnalytics.outputs.id
    tags: tags
  }
}

module appServicePlan './modules/appServicePlan.bicep' = {
  params: {
    name: planName
    location: location
    sku: appServiceSku
    tags: tags
  }
}

module aiFoundry './modules/aiFoundry.bicep' = {
  params: {
    name: aiAccountName
    location: location
    sku: aiSku
    tags: tags
  }
}

module webApp './modules/webApp.bicep' = {
  params: {
    name: webAppName
    location: location
    serviceName: 'web'
    serverFarmId: appServicePlan.outputs.id
    acrLoginServer: acr.outputs.loginServer
    imageName: imageName
    imageTag: imageTag
    applicationInsightsConnectionString: appInsights.outputs.connectionString
    aiEndpoint: aiFoundry.outputs.endpoint
    tags: tags
  }
}

module acrPullAssignment './modules/roleAssignmentAcrPull.bicep' = {
  params: {
    principalId: webApp.outputs.principalId
    acrName: acr.outputs.name
  }
}

output webAppName string = webApp.outputs.name
output webAppUrl string = webApp.outputs.url
output acrName string = acr.outputs.name
output aiEndpoint string = aiFoundry.outputs.endpoint
