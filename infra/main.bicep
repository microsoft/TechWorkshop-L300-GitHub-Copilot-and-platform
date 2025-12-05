// Main Bicep Template
// Orchestrates the deployment of Azure infrastructure for ZavaStorefront
// Deploys: Log Analytics, App Insights, ACR, App Service Plan, Web App, Role Assignments

targetScope = 'subscription'

@description('The name of the environment (e.g., dev, staging, prod)')
@minLength(1)
@maxLength(64)
param environmentName string

@description('The location for all resources')
@allowed([
  'westus3'
  'eastus'
  'eastus2'
  'westus2'
  'centralus'
])
param location string = 'westus3'

@description('The SKU for the Container Registry')
@allowed([
  'Basic'
  'Standard'
])
param acrSku string = 'Standard'

@description('The SKU for the App Service Plan')
@allowed([
  'B1'
  'B2'
  'S1'
])
param appServiceSku string = 'B1'

// Generate unique resource names using environment and location
var abbrs = {
  resourceGroup: 'rg-'
  logAnalytics: 'log-'
  appInsights: 'appi-'
  containerRegistry: 'cr'
  appServicePlan: 'plan-'
  webApp: 'app-'
}

var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var resourceGroupName = '${abbrs.resourceGroup}zavastore-${environmentName}-${location}'

// Use shorter environment name for resource naming (max 10 chars)
var shortEnvName = take(environmentName, 10)

var tags = {
  'azd-env-name': environmentName
  environment: environmentName
  application: 'zavastore'
}

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Log Analytics Workspace
module logAnalytics 'modules/logAnalytics.bicep' = {
  name: 'logAnalytics'
  scope: rg
  params: {
    name: '${abbrs.logAnalytics}zavastore-${shortEnvName}'
    location: location
    tags: tags
  }
}

// Application Insights
module appInsights 'modules/appInsights.bicep' = {
  name: 'appInsights'
  scope: rg
  params: {
    name: '${abbrs.appInsights}zavastore-${shortEnvName}'
    location: location
    tags: tags
    workspaceResourceId: logAnalytics.outputs.id
  }
}

// Azure Container Registry
// Note: ACR names must be globally unique, alphanumeric only, 5-50 characters
module acr 'modules/acr.bicep' = {
  name: 'acr'
  scope: rg
  params: {
    name: '${abbrs.containerRegistry}zavastore${resourceToken}'
    location: location
    tags: tags
    sku: acrSku
    adminUserEnabled: false
  }
}

// App Service (Plan + Web App)
module appService 'modules/appService.bicep' = {
  name: 'appService'
  scope: rg
  params: {
    appServicePlanName: '${abbrs.appServicePlan}zavastore-${shortEnvName}'
    webAppName: '${abbrs.webApp}zavastore-${shortEnvName}-${resourceToken}'
    location: location
    tags: tags
    skuName: appServiceSku
    acrLoginServer: acr.outputs.loginServer
    appInsightsConnectionString: appInsights.outputs.connectionString
    appInsightsInstrumentationKey: appInsights.outputs.instrumentationKey
  }
}

// Role Assignment: AcrPull for Web App managed identity on ACR
// This allows the Web App to pull container images from ACR using managed identity
module acrPullRoleAssignment 'modules/roleAssignment.bicep' = {
  name: 'acrPullRoleAssignment'
  scope: rg
  params: {
    principalId: appService.outputs.webAppPrincipalId
    roleDefinitionId: '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull built-in role
    principalType: 'ServicePrincipal'
    targetResourceId: acr.outputs.id
  }
}

// Outputs for AZD and downstream usage
output AZURE_RESOURCE_GROUP string = rg.name
output AZURE_LOCATION string = location
output AZURE_CONTAINER_REGISTRY_NAME string = acr.outputs.name
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = acr.outputs.loginServer
output AZURE_APP_SERVICE_PLAN_NAME string = appService.outputs.appServicePlanName
output AZURE_WEB_APP_NAME string = appService.outputs.webAppName
output AZURE_WEB_APP_HOSTNAME string = appService.outputs.webAppHostname
output AZURE_APP_INSIGHTS_NAME string = appInsights.outputs.name
output AZURE_APP_INSIGHTS_CONNECTION_STRING string = appInsights.outputs.connectionString
output AZURE_LOG_ANALYTICS_WORKSPACE_NAME string = logAnalytics.outputs.name
