// Main Bicep template for ZavaStorefront infrastructure
// Orchestrates all Azure resources for the dev environment

targetScope = 'subscription'

// ============================================================================
// Parameters
// ============================================================================

@description('Name of the environment (e.g., dev, staging, prod)')
param environmentName string

@description('Primary location for all resources')
param location string = 'westus3'

@description('Name of the application')
param appName string = 'zavastore'

@description('Container image name and tag')
param containerImageName string = 'zavastore:latest'

// ============================================================================
// Variables
// ============================================================================

var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = {
  'azd-env-name': environmentName
  'app-name': appName
  environment: 'dev'
}

/*var serviceTags = union(commonTags, {
  'azd-service-name': 'src'
})*/

// Resource naming (following Azure naming conventions)
var resourceGroupName = 'rg-${appName}-${environmentName}-${location}'
var logAnalyticsName = 'log-${appName}-${resourceToken}'
var appInsightsName = 'appi-${appName}-${resourceToken}'
var containerRegistryName = 'cr${appName}${resourceToken}'
var appServicePlanName = 'asp-${appName}-${resourceToken}'
var webAppName = 'app-${appName}-${resourceToken}'

// ============================================================================
// Resource Group
// ============================================================================

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// ============================================================================
// Modules
// ============================================================================

// Log Analytics Workspace
module logAnalytics 'modules/logAnalytics.bicep' = {
  name: 'logAnalyticsDeployment'
  scope: rg
  params: {
    name: logAnalyticsName
    location: location
    tags: tags
    retentionInDays: 30
  }
}

// Application Insights
module appInsights 'modules/appInsights.bicep' = {
  name: 'appInsightsDeployment'
  scope: rg
  params: {
    name: appInsightsName
    location: location
    tags: tags
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
  }
}

// Azure Container Registry
module containerRegistry 'modules/acr.bicep' = {
  name: 'containerRegistryDeployment'
  scope: rg
  params: {
    name: containerRegistryName
    location: location
    tags: tags
    sku: 'Basic'
    adminUserEnabled: false
  }
}

// App Service (Plan + Web App)
module appService 'modules/appService.bicep' = {
  name: 'appServiceDeployment'
  scope: rg
  params: {
    name: webAppName
    appServicePlanName: appServicePlanName
    location: location
    tags: tags
    skuName: 'B1'
    skuTier: 'Basic'
    containerRegistryLoginServer: containerRegistry.outputs.loginServer
    containerImageName: containerImageName
    appInsightsConnectionString: appInsights.outputs.connectionString
    appInsightsInstrumentationKey: appInsights.outputs.instrumentationKey
  }
}

// AcrPull Role Assignment - Allow Web App to pull images from ACR using managed identity
module acrPullRoleAssignment 'modules/roleAssignment.bicep' = {
  name: 'acrPullRoleAssignmentDeployment'
  scope: rg
  params: {
    principalId: appService.outputs.principalId
    roleDefinitionId: '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull role
    principalType: 'ServicePrincipal'
    containerRegistryName: containerRegistry.outputs.name
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('The name of the resource group')
output AZURE_RESOURCE_GROUP string = rg.name

@description('The location of the resources')
output AZURE_LOCATION string = location

@description('The name of the Container Registry')
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name

@description('The login server of the Container Registry')
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer

@description('The name of the Web App')
output AZURE_WEB_APP_NAME string = appService.outputs.name

@description('The URL of the Web App')
output AZURE_WEB_APP_URL string = 'https://${appService.outputs.defaultHostname}'

@description('The Application Insights connection string')
output APPLICATIONINSIGHTS_CONNECTION_STRING string = appInsights.outputs.connectionString
