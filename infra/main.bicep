// Main Bicep Template - ZavaStorefront Infrastructure
// Orchestrates all modules for a dev environment in westus3
// Resources: ACR, App Service (Linux/Container), App Insights, Log Analytics, AI Foundry
// Image pulls use Azure RBAC managed identity (no passwords)

targetScope = 'resourceGroup'

@minLength(1)
@maxLength(64)
@description('Name of the environment (e.g. dev, staging, prod)')
param environmentName string

@minLength(1)
@description('Azure region for all resources')
param location string = 'westus3'

@description('Container image to deploy (set by azd during deploy)')
param containerImage string = 'mcr.microsoft.com/appsvc/staticsite:latest'

// Generate resource name tokens
var resourceToken = toLower(uniqueString(subscription().id, resourceGroup().id, environmentName))
var abbrs = {
  acr: 'acr'
  appServicePlan: 'asp'
  webApp: 'app'
  appInsights: 'appi'
  logAnalytics: 'log'
  aiHub: 'aihub'
  aiProject: 'aiproj'
  aiServices: 'ais'
}

var tags = {
  'azd-env-name': environmentName
  environment: environmentName
  application: 'zava-storefront'
}

// Azure Container Registry
module acr 'modules/acr.bicep' = {
  name: 'acr'
  params: {
    acrName: '${abbrs.acr}${resourceToken}'
    location: location
    acrSku: 'Basic'
    tags: tags
  }
}

// Log Analytics Workspace (backend for App Insights)
module logAnalytics 'modules/logAnalytics.bicep' = {
  name: 'logAnalytics'
  params: {
    logAnalyticsName: '${abbrs.logAnalytics}-zava-${environmentName}-${resourceToken}'
    location: location
    tags: tags
  }
}

// Application Insights
module appInsights 'modules/appInsights.bicep' = {
  name: 'appInsights'
  params: {
    appInsightsName: '${abbrs.appInsights}-zava-${environmentName}-${resourceToken}'
    location: location
    logAnalyticsId: logAnalytics.outputs.logAnalyticsId
    tags: tags
  }
}

// App Service (Linux Web App for Containers)
module appService 'modules/appService.bicep' = {
  name: 'appService'
  params: {
    appServicePlanName: '${abbrs.appServicePlan}-zava-${environmentName}-${resourceToken}'
    webAppName: '${abbrs.webApp}-zava-${environmentName}-${resourceToken}'
    location: location
    acrLoginServer: acr.outputs.acrLoginServer
    containerImage: containerImage
    appInsightsConnectionString: appInsights.outputs.appInsightsConnectionString
    appInsightsInstrumentationKey: appInsights.outputs.appInsightsInstrumentationKey
    appServicePlanSku: 'B1'
    tags: tags
  }
}

// AcrPull Role Assignment (managed identity -> ACR)
module roleAssignment 'modules/roleAssignment.bicep' = {
  name: 'roleAssignment'
  params: {
    acrId: acr.outputs.acrId
    webAppPrincipalId: appService.outputs.webAppPrincipalId
  }
}

// AI Foundry (Hub + Project + AI Services with GPT-4o and Phi-4)
module aiFoundry 'modules/aiFoundry.bicep' = {
  name: 'aiFoundry'
  params: {
    aiHubName: '${abbrs.aiHub}-zava-${environmentName}-${resourceToken}'
    aiProjectName: '${abbrs.aiProject}-zava-${environmentName}-${resourceToken}'
    aiServicesName: '${abbrs.aiServices}-zava-${environmentName}-${resourceToken}'
    location: location
    tags: tags
  }
}

// Outputs consumed by AZD and application
output AZURE_LOCATION string = location
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = acr.outputs.acrLoginServer
output AZURE_CONTAINER_REGISTRY_NAME string = acr.outputs.acrName
output SERVICE_WEB_NAME string = appService.outputs.webAppName
output SERVICE_WEB_URI string = 'https://${appService.outputs.webAppHostname}'
output APPLICATIONINSIGHTS_CONNECTION_STRING string = appInsights.outputs.appInsightsConnectionString
output AZURE_AI_SERVICES_ENDPOINT string = aiFoundry.outputs.aiServicesEndpoint
