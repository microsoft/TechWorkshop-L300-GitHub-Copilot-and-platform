targetScope = 'resourceGroup'

@description('Environment name (e.g. dev)')
param environmentName string = 'dev'

@description('Location for all resources')
param location string = 'westus3'

@description('Container image tag to deploy')
param containerImageTag string = 'latest'

// ── Derived / generated names ─────────────────────────────────────────────────
var suffix = uniqueString(resourceGroup().id)
var acrName = 'acrzavastore${environmentName}${take(suffix, 6)}'
var planName = 'plan-zavastore-${environmentName}'
var webAppName = 'app-zavastore-${environmentName}-${take(suffix, 6)}'
var appInsightsName = 'ai-zavastore-${environmentName}'
var logAnalyticsName = 'log-zavastore-${environmentName}'
var aiHubName = 'hub-zavastore-${environmentName}-${take(suffix, 6)}'
var aiProjectName = 'proj-zavastore-${environmentName}-${take(suffix, 6)}'

var tags = {
  environment: environmentName
  application: 'ZavaStorefront'
  managedBy: 'bicep'
}

// ── Modules ───────────────────────────────────────────────────────────────────

module acr 'modules/acr.bicep' = {
  name: 'acr'
  params: {
    acrName: acrName
    location: location
    acrSku: 'Basic'
    tags: tags
  }
}

module appServicePlan 'modules/appserviceplan.bicep' = {
  name: 'appServicePlan'
  params: {
    planName: planName
    location: location
    skuName: 'B1'
    tags: tags
  }
}

module appInsights 'modules/appinsights.bicep' = {
  name: 'appInsights'
  params: {
    appInsightsName: appInsightsName
    logAnalyticsName: logAnalyticsName
    location: location
    tags: tags
  }
}

module webApp 'modules/webapp.bicep' = {
  name: 'webApp'
  params: {
    webAppName: webAppName
    location: location
    appServicePlanId: appServicePlan.outputs.planId
    acrLoginServer: acr.outputs.acrLoginServer
    containerImage: 'zavastore:${containerImageTag}'
    appInsightsConnectionString: appInsights.outputs.appInsightsConnectionString
    aiServicesEndpoint: aiFoundry.outputs.aiServicesEndpoint
    contentSafetyEndpoint: aiFoundry.outputs.aiServicesEndpoint
    tags: tags
  }
  dependsOn: [aiFoundry]
}

module acrPullRole 'modules/roleassignment.bicep' = {
  name: 'acrPullRole'
  params: {
    principalId: webApp.outputs.webAppPrincipalId
    acrId: acr.outputs.acrId
    aiServicesId: aiFoundry.outputs.aiServicesId
  }
  dependsOn: [aiFoundry]
}

module aiFoundry 'modules/aifoundry.bicep' = {
  name: 'aiFoundry'
  params: {
    aiHubName: aiHubName
    aiProjectName: aiProjectName
    location: location
    logAnalyticsWorkspaceId: appInsights.outputs.logAnalyticsWorkspaceId
    tags: tags
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────
output acrLoginServer string = acr.outputs.acrLoginServer
output acrName string = acr.outputs.acrName
output webAppName string = webApp.outputs.webAppName
output webAppUrl string = 'https://${webApp.outputs.webAppDefaultHostName}'
output appInsightsConnectionString string = appInsights.outputs.appInsightsConnectionString
output aiServicesEndpoint string = aiFoundry.outputs.aiServicesEndpoint
