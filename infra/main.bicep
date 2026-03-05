targetScope = 'subscription'

// ============================================================================
// PARAMETERS
// ============================================================================

@description('Environment name (e.g., dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environmentName string = 'dev'

@description('Location for all resources')
param location string = 'swedencentral'

@description('Application name used for resource naming')
param appName string = 'zavastore'

@description('SKU for App Service Plan')
param appServiceSkuName string = 'B1'

@description('SKU for Container Registry')
@allowed(['Basic', 'Standard', 'Premium'])
param acrSku string = 'Basic'

@description('Docker image name and tag for the web app')
param dockerImageName string = 'zavastore:latest'

@description('Tags to apply to all resources')
param tags object = {}

// ============================================================================
// VARIABLES
// ============================================================================

// Unique suffix to avoid DNS name conflicts (use your alias)
var uniqueSuffix = 'singhha'

var resourceGroupName = 'rg-${appName}-${environmentName}-${location}'

// Resource naming with consistent pattern (added uniqueSuffix to globally unique resources)
var acrName = replace('acr${appName}${uniqueSuffix}${environmentName}', '-', '')
var appServicePlanName = 'asp-${appName}-${uniqueSuffix}-${environmentName}'
var webAppName = 'app-${appName}-${uniqueSuffix}-${environmentName}'
var appInsightsName = 'appi-${appName}-${environmentName}-${location}'
var logAnalyticsName = 'log-${appName}-${environmentName}-${location}'
var aiServicesName = 'ai-${appName}-${environmentName}-${location}'

// Merge default tags with provided tags
var defaultTags = {
  environment: environmentName
  application: appName
  'azd-env-name': environmentName
}
var allTags = union(defaultTags, tags)

// ============================================================================
// RESOURCE GROUP
// ============================================================================

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: allTags
}

// ============================================================================
// MODULES
// ============================================================================

// Azure Container Registry
module containerRegistry 'modules/containerRegistry.bicep' = {
  scope: resourceGroup
  params: {
    name: acrName
    location: location
    sku: acrSku
    tags: allTags
  }
}

// Application Insights and Log Analytics
module appInsights 'modules/appInsights.bicep' = {
  scope: resourceGroup
  params: {
    appInsightsName: appInsightsName
    logAnalyticsName: logAnalyticsName
    location: location
    tags: allTags
  }
}

// App Service Plan
module appServicePlan 'modules/appServicePlan.bicep' = {
  scope: resourceGroup
  params: {
    name: appServicePlanName
    location: location
    skuName: appServiceSkuName
    tags: allTags
  }
}

// Azure AI Services (Foundry)
module aiFoundry 'modules/aiFoundry.bicep' = {
  scope: resourceGroup
  params: {
    name: aiServicesName
    location: location
    tags: allTags
  }
}

// Web App for Containers
module webApp 'modules/webApp.bicep' = {
  scope: resourceGroup
  params: {
    name: webAppName
    location: location
    appServicePlanId: appServicePlan.outputs.id
    acrLoginServer: containerRegistry.outputs.loginServer
    dockerImageName: dockerImageName
    appInsightsConnectionString: appInsights.outputs.connectionString
    aiEndpoint: aiFoundry.outputs.endpoint
    tags: allTags
  }
}

// Role Assignment: Grant Web App AcrPull access to ACR
module acrPullRoleAssignment 'modules/roleAssignment.bicep' = {
  scope: resourceGroup
  params: {
    principalId: webApp.outputs.principalId
    principalType: 'ServicePrincipal'
    acrId: containerRegistry.outputs.id
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

@description('The name of the resource group')
output AZURE_RESOURCE_GROUP string = resourceGroup.name

@description('The name of the container registry')
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name

@description('The login server URL of the container registry')
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer

@description('The name of the web app')
output AZURE_WEB_APP_NAME string = webApp.outputs.name

@description('The URL of the web app')
output AZURE_WEB_APP_URL string = 'https://${webApp.outputs.hostname}'

@description('The Application Insights connection string')
output APPLICATIONINSIGHTS_CONNECTION_STRING string = appInsights.outputs.connectionString

@description('The Azure AI endpoint')
output AZURE_AI_ENDPOINT string = aiFoundry.outputs.endpoint

@description('The name of the Azure AI Services account')
output AZURE_AI_NAME string = aiFoundry.outputs.name
