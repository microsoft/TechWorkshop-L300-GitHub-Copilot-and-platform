// ============================================================================
// Main Bicep Template - ZavaStorefront Infrastructure
// Deploys all Azure resources for the ZavaStorefront web application
// ============================================================================

targetScope = 'resourceGroup'

// ============================================================================
// Parameters
// ============================================================================

@description('Name of the environment (e.g., dev, staging, prod)')
param environmentName string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Base name for all resources')
param baseName string = 'zavastore'

@description('Tags to apply to all resources')
param tags object = {}

@description('SKU for the App Service Plan')
@allowed([
  'B1'
  'B2'
  'B3'
  'S1'
  'P1v2'
])
param appServicePlanSku string = 'B1'

@description('SKU for the Azure Container Registry')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param acrSku string = 'Basic'

@description('Whether to deploy AI Services')
param deployAiServices bool = true

@description('Whether to deploy GPT-4o model')
param deployGpt4o bool = true

@description('Whether to deploy Phi model')
param deployPhi bool = true

// ============================================================================
// Variables
// ============================================================================

// Generate unique suffix for globally unique names
var resourceToken = toLower(uniqueString(resourceGroup().id, environmentName, location))

// Resource names following Azure naming conventions
var logAnalyticsName = 'log-${baseName}-${environmentName}-${resourceToken}'
var appInsightsName = 'appi-${baseName}-${environmentName}-${resourceToken}'
var acrName = 'acr${baseName}${environmentName}${resourceToken}'
var appServicePlanName = 'asp-${baseName}-${environmentName}-${resourceToken}'
var webAppName = 'app-${baseName}-${environmentName}-${resourceToken}'
var aiServicesName = 'ai-${baseName}-${environmentName}-${resourceToken}'

// Merged tags
var defaultTags = {
  'azd-env-name': environmentName
  application: 'ZavaStorefront'
  environment: environmentName
}
var allTags = union(defaultTags, tags)

// ============================================================================
// Modules
// ============================================================================

// Log Analytics Workspace - Central logging
module logAnalytics 'modules/logAnalytics.bicep' = {
  name: 'logAnalyticsDeployment-${uniqueString(resourceGroup().id, deployment().name)}'
  params: {
    name: logAnalyticsName
    location: location
    tags: allTags
    skuName: 'PerGB2018'
    retentionInDays: 30
  }
}

// Application Insights - Application monitoring
module appInsights 'modules/appInsights.bicep' = {
  name: 'appInsightsDeployment-${uniqueString(resourceGroup().id, deployment().name)}'
  params: {
    name: appInsightsName
    location: location
    tags: allTags
    workspaceResourceId: logAnalytics.outputs.resourceId
    kind: 'web'
  }
}

// Azure Container Registry - Container image storage
module acr 'modules/acr.bicep' = {
  name: 'acrDeployment-${uniqueString(resourceGroup().id, deployment().name)}'
  params: {
    name: acrName
    location: location
    tags: allTags
    skuName: acrSku
    adminUserEnabled: false
  }
}

// App Service Plan - Linux hosting plan
module appServicePlan 'modules/appServicePlan.bicep' = {
  name: 'appServicePlanDeployment-${uniqueString(resourceGroup().id, deployment().name)}'
  params: {
    name: appServicePlanName
    location: location
    tags: allTags
    skuName: appServicePlanSku
    skuCapacity: 1
  }
}

// Web App - Linux container app
module webApp 'modules/appService.bicep' = {
  name: 'webAppDeployment-${uniqueString(resourceGroup().id, deployment().name)}'
  params: {
    name: webAppName
    location: location
    tags: allTags
    serverFarmResourceId: appServicePlan.outputs.resourceId
    linuxFxVersion: 'DOCKER|${acr.outputs.loginServer}/zavastore:latest'
    appInsightsConnectionString: appInsights.outputs.connectionString
    acrLoginServer: acr.outputs.loginServer
  }
}

// Role Assignment - AcrPull role for Web App managed identity
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, webAppName, 'acrpull')
  scope: resourceGroup()
  properties: {
    principalId: webApp.outputs.systemAssignedMIPrincipalId
    principalType: 'ServicePrincipal'
    // AcrPull built-in role
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  }
}

// AI Services - GPT-4 and Phi models (optional)
module aiServices 'modules/cognitiveServices.bicep' = if (deployAiServices) {
  name: 'aiServicesDeployment-${uniqueString(resourceGroup().id, deployment().name)}'
  params: {
    name: aiServicesName
    location: location
    tags: allTags
    skuName: 'S0'
    kind: 'AIServices'
    deployGpt4o: deployGpt4o
    deployPhi: deployPhi
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('The name of the resource group')
output AZURE_RESOURCE_GROUP string = resourceGroup().name

@description('The location of the resources')
output AZURE_LOCATION string = location

@description('The name of the Log Analytics workspace')
output LOG_ANALYTICS_NAME string = logAnalytics.outputs.name

@description('The name of the Application Insights')
output APPLICATION_INSIGHTS_NAME string = appInsights.outputs.name

@description('The connection string of the Application Insights')
output APPLICATIONINSIGHTS_CONNECTION_STRING string = appInsights.outputs.connectionString

@description('The name of the Azure Container Registry')
output AZURE_CONTAINER_REGISTRY_NAME string = acr.outputs.name

@description('The login server of the Azure Container Registry')
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = acr.outputs.loginServer

@description('The name of the App Service Plan')
output APP_SERVICE_PLAN_NAME string = appServicePlan.outputs.name

@description('The name of the Web App')
output AZURE_APP_SERVICE_NAME string = webApp.outputs.name

@description('The default hostname of the Web App')
output SERVICE_WEB_ENDPOINT string = 'https://${webApp.outputs.defaultHostname}'

@description('The name of the AI Services account')
output AI_SERVICES_NAME string = deployAiServices ? aiServices!.outputs.name : ''

@description('The endpoint of the AI Services account')
output AI_SERVICES_ENDPOINT string = deployAiServices ? aiServices!.outputs.endpoint : ''
