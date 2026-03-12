@description('Azure region for all resources')
param location string = 'westus3'

@description('Environment short name, for example dev')
param environmentName string = 'dev'

@description('Base name for all resources')
param workloadName string = 'zavastore'

@description('ACR SKU for development environments')
@allowed([
  'Basic'
  'Standard'
])
param acrSku string = 'Basic'

@description('App Service Plan SKU name')
param appServicePlanSku string = 'B1'

@description('Linux runtime for App Service worker')
param linuxFxVersion string = 'DOTNETCORE|6.0'

@description('Container image repository in ACR')
param imageRepository string = 'zavastorefront'

@description('Container image tag in ACR')
param imageTag string = 'latest'

@description('Azure AI Foundry (Azure OpenAI) SKU')
param foundrySku string = 'S0'

var suffix = toLower(uniqueString(subscription().id, resourceGroup().id, workloadName, environmentName))
var acrName = take(replace('${workloadName}${environmentName}${suffix}', '-', ''), 50)
var logAnalyticsName = '${workloadName}-${environmentName}-law'
var appInsightsName = '${workloadName}-${environmentName}-appi'
var appServicePlanName = '${workloadName}-${environmentName}-asp'
var webAppName = take('${workloadName}-${environmentName}-web-${take(suffix, 6)}', 60)
var foundryAccountName = take('${workloadName}-${environmentName}-foundry-${take(suffix, 6)}', 64)

module acr './modules/acr.bicep' = {
  name: 'acrModule'
  params: {
    acrName: acrName
    location: location
    sku: acrSku
  }
}

module logAnalytics './modules/logAnalytics.bicep' = {
  name: 'logAnalyticsModule'
  params: {
    workspaceName: logAnalyticsName
    location: location
  }
}

module appInsights './modules/appInsights.bicep' = {
  name: 'appInsightsModule'
  params: {
    appInsightsName: appInsightsName
    location: location
    workspaceResourceId: logAnalytics.outputs.workspaceResourceId
  }
}

module appServicePlan './modules/appServicePlan.bicep' = {
  name: 'appServicePlanModule'
  params: {
    planName: appServicePlanName
    location: location
    skuName: appServicePlanSku
  }
}

module webApp './modules/webAppContainer.bicep' = {
  name: 'webAppModule'
  params: {
    webAppName: webAppName
    location: location
    appServicePlanId: appServicePlan.outputs.planResourceId
    appInsightsConnectionString: appInsights.outputs.connectionString
    acrLoginServer: acr.outputs.loginServer
    containerImage: '${imageRepository}:${imageTag}'
    linuxFxVersion: linuxFxVersion
  }
}

module acrPullAssignment './modules/roleAssignmentAcrPull.bicep' = {
  name: 'acrPullRoleAssignmentModule'
  params: {
    principalId: webApp.outputs.principalId
    acrResourceId: acr.outputs.acrResourceId
  }
}

module foundry './modules/foundry.bicep' = {
  name: 'foundryModule'
  params: {
    accountName: foundryAccountName
    location: location
    skuName: foundrySku
  }
}

output acrName string = acrName
output acrLoginServer string = acr.outputs.loginServer
output webAppName string = webAppName
output webAppDefaultHostName string = webApp.outputs.defaultHostName
output appInsightsName string = appInsightsName
output foundryAccountName string = foundry.outputs.accountName
