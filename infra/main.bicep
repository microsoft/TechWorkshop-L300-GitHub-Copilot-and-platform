targetScope = 'resourceGroup'

// ─── Parameters ───────────────────────────────────────────────
@description('Primary location for all resources')
param location string = resourceGroup().location

@description('Environment name (dev, staging, prod)')
param environmentName string = 'dev'

@description('Base name used for generating resource names')
param baseName string = 'zavastore'

// ─── Existing-resource flags ──────────────────────────────────
// Set these to true and provide the existing resource name
// to skip creation and reference an already-deployed resource.

@description('If true, reference an existing ACR instead of creating one')
param useExistingAcr bool = false
@description('Name of the existing ACR (required when useExistingAcr is true)')
param existingAcrName string = ''

@description('If true, reference an existing Log Analytics workspace')
param useExistingLogAnalytics bool = false
@description('Name of the existing Log Analytics workspace')
param existingLogAnalyticsName string = ''

@description('If true, reference an existing Application Insights instance')
param useExistingAppInsights bool = false
@description('Name of the existing Application Insights instance')
param existingAppInsightsName string = ''

@description('If true, reference an existing App Service Plan')
param useExistingAppServicePlan bool = false
@description('Name of the existing App Service Plan')
param existingAppServicePlanName string = ''

@description('If true, reference an existing Web App')
param useExistingWebApp bool = false
@description('Name of the existing Web App')
param existingWebAppName string = ''

@description('If true, skip AI Services deployment')
param useExistingAiServices bool = false
@description('Name of the existing AI Services account')
param existingAiServicesName string = ''

// ─── Naming ───────────────────────────────────────────────────
var suffix = uniqueString(resourceGroup().id)
var acrName = useExistingAcr ? existingAcrName : 'acr${baseName}${suffix}'
var logAnalyticsName = useExistingLogAnalytics ? existingLogAnalyticsName : 'log-${baseName}-${environmentName}'
var appInsightsName = useExistingAppInsights ? existingAppInsightsName : 'appi-${baseName}-${environmentName}'
var appServicePlanName = useExistingAppServicePlan ? existingAppServicePlanName : 'plan-${baseName}-${environmentName}'
var webAppName = useExistingWebApp ? existingWebAppName : 'app-${baseName}-${environmentName}-${suffix}'
var aiServicesName = useExistingAiServices ? existingAiServicesName : 'ai-${baseName}-${environmentName}'

// ─── Modules ──────────────────────────────────────────────────

module logAnalytics 'modules/logAnalytics.bicep' = {
  name: 'logAnalytics'
  params: {
    name: logAnalyticsName
    location: location
    useExisting: useExistingLogAnalytics
  }
}

module appInsights 'modules/appInsights.bicep' = {
  name: 'appInsights'
  params: {
    name: appInsightsName
    location: location
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
    useExisting: useExistingAppInsights
  }
}

module acr 'modules/containerRegistry.bicep' = {
  name: 'containerRegistry'
  params: {
    name: acrName
    location: location
    useExisting: useExistingAcr
  }
}

module appServicePlan 'modules/appServicePlan.bicep' = {
  name: 'appServicePlan'
  params: {
    name: appServicePlanName
    location: location
    useExisting: useExistingAppServicePlan
  }
}

module webApp 'modules/webApp.bicep' = {
  name: 'webApp'
  params: {
    name: webAppName
    location: location
    appServicePlanId: appServicePlan.outputs.id
    appInsightsConnectionString: appInsights.outputs.connectionString
    appInsightsInstrumentationKey: appInsights.outputs.instrumentationKey
    acrLoginServer: acr.outputs.loginServer
    useExisting: useExistingWebApp
  }
}

// AcrPull role assignment — always applied so the managed identity can pull
module acrPullRole 'modules/acrPullRole.bicep' = {
  name: 'acrPullRole'
  params: {
    acrName: acr.outputs.name
    principalId: webApp.outputs.principalId
  }
}

module aiServices 'modules/aiServices.bicep' = {
  name: 'aiServices'
  params: {
    name: aiServicesName
    location: location
    useExisting: useExistingAiServices
  }
}

// ─── Outputs ──────────────────────────────────────────────────
output AZURE_ACR_NAME string = acr.outputs.name
output AZURE_ACR_LOGIN_SERVER string = acr.outputs.loginServer
output AZURE_WEB_APP_NAME string = webApp.outputs.name
output AZURE_WEB_APP_HOSTNAME string = webApp.outputs.defaultHostName
output AZURE_APPINSIGHTS_NAME string = appInsights.outputs.name
output AZURE_AI_SERVICES_NAME string = aiServices.outputs.name
output AZURE_AI_SERVICES_ENDPOINT string = aiServices.outputs.endpoint
