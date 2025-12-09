targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string = 'westus3'

@description('Name of the resource group')
param resourceGroupName string = ''

@description('Name of the App Service Plan')
param appServicePlanName string = ''

@description('Name of the App Service')
param appServiceName string = ''

@description('Name of the Container Registry')
param containerRegistryName string = ''

@description('Name of the Log Analytics workspace')
param logAnalyticsName string = ''

@description('Name of the Application Insights')
param applicationInsightsName string = ''

@description('Name of the Azure AI Foundry account')
param aiFoundryAccountName string = ''

@description('SKU for App Service Plan')
param appServicePlanSku string = 'B1'

@description('SKU for Container Registry')
param containerRegistrySku string = 'Basic'

// Load abbreviations for naming convention
var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

// Generate resource names using naming convention
var _resourceGroupName = !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourceGroup}${environmentName}'
var _appServicePlanName = !empty(appServicePlanName) ? appServicePlanName : '${abbrs.appServicePlan}${resourceToken}'
var _appServiceName = !empty(appServiceName) ? appServiceName : '${abbrs.appServiceWebApp}${resourceToken}'
var _containerRegistryName = !empty(containerRegistryName) ? containerRegistryName : '${abbrs.containerRegistry}${resourceToken}'
var _logAnalyticsName = !empty(logAnalyticsName) ? logAnalyticsName : '${abbrs.logAnalyticsWorkspace}${resourceToken}'
var _applicationInsightsName = !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.applicationInsights}${resourceToken}'
var _aiFoundryAccountName = !empty(aiFoundryAccountName) ? aiFoundryAccountName : '${abbrs.cognitiveServicesAccount}${resourceToken}'

// Tags for all resources
var tags = {
  'azd-env-name': environmentName
  environment: 'dev'
  application: 'ZavaStorefront'
}

// Create Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: _resourceGroupName
  location: location
  tags: tags
}

// Deploy Monitoring (Log Analytics + Application Insights)
module monitoring './modules/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    logAnalyticsName: _logAnalyticsName
    applicationInsightsName: _applicationInsightsName
    tags: tags
  }
}

// Deploy Azure Container Registry
module acr './modules/acr.bicep' = {
  name: 'acr'
  scope: rg
  params: {
    location: location
    containerRegistryName: _containerRegistryName
    sku: containerRegistrySku
    tags: tags
  }
}

// Deploy App Service (Plan + Web App)
module appService './modules/appservice.bicep' = {
  name: 'appservice'
  scope: rg
  params: {
    location: location
    appServicePlanName: _appServicePlanName
    appServiceName: _appServiceName
    sku: appServicePlanSku
    containerRegistryLoginServer: acr.outputs.loginServer
    applicationInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
    applicationInsightsInstrumentationKey: monitoring.outputs.applicationInsightsInstrumentationKey
    tags: tags
  }
}

// Assign ACR Pull role to App Service managed identity
module acrRoleAssignment './modules/acr-role-assignment.bicep' = {
  name: 'acrRoleAssignment'
  scope: rg
  params: {
    containerRegistryName: acr.outputs.containerRegistryName
    principalId: appService.outputs.appServicePrincipalId
  }
}

// Deploy Azure AI Foundry
module aiFoundry './modules/ai-foundry.bicep' = {
  name: 'aiFoundry'
  scope: rg
  params: {
    location: location
    aiFoundryAccountName: _aiFoundryAccountName
    tags: tags
  }
}

// Outputs for AZD
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP string = rg.name

output ACR_NAME string = acr.outputs.containerRegistryName
output ACR_LOGIN_SERVER string = acr.outputs.loginServer

output SERVICE_WEB_NAME string = appService.outputs.appServiceName
output SERVICE_WEB_URI string = appService.outputs.appServiceUri
output SERVICE_WEB_IMAGE_NAME string = 'zava-storefront'

output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.applicationInsightsConnectionString

output AI_FOUNDRY_ENDPOINT string = aiFoundry.outputs.endpoint
output AI_FOUNDRY_NAME string = aiFoundry.outputs.accountName
