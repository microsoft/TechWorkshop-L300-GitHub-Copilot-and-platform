targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment (e.g., dev, staging, prod)')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Base name for the application')
param appName string = 'zavastore'

@description('SKU for the Azure Container Registry')
@allowed(['Basic', 'Standard', 'Premium'])
param acrSku string = 'Basic'

@description('SKU for the App Service Plan')
param appServicePlanSku string = 'B1'

@description('Container image name')
param containerImageName string = 'zavastore:latest'

@description('SKU for Microsoft Foundry')
param foundrySku string = 'S0'

@description('AI model deployments for Microsoft Foundry (leave empty to skip model deployments)')
param foundryModelDeployments array = []

var abbrs = {
  resourceGroup: 'rg'
  containerRegistry: 'acr'
  appServicePlan: 'asp'
  webApp: 'app'
  appInsights: 'appi'
  logAnalytics: 'log'
  cognitiveServices: 'foundry'
}

// Generate unique suffix for globally unique resources
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

// Resource names
var resourceGroupName = '${abbrs.resourceGroup}-${appName}-${environmentName}-${location}'
var containerRegistryName = '${abbrs.containerRegistry}${appName}${environmentName}${resourceToken}'
var appServicePlanName = '${abbrs.appServicePlan}-${appName}-${environmentName}-${location}'
var webAppName = '${abbrs.webApp}-${appName}-${environmentName}-${resourceToken}'
var appInsightsName = '${abbrs.appInsights}-${appName}-${environmentName}-${location}'
var logAnalyticsName = '${abbrs.logAnalytics}-${appName}-${environmentName}-${location}'
var foundryName = '${abbrs.cognitiveServices}-${appName}-${environmentName}-${location}'

// Tags to apply to all resources
var tags = {
  'azd-env-name': environmentName
  'app-name': appName
  environment: environmentName
}

// Resource Group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Container Registry
module containerRegistry 'modules/containerRegistry.bicep' = {
  scope: resourceGroup
  name: 'containerRegistry'
  params: {
    location: location
    registryName: containerRegistryName
    sku: acrSku
    tags: tags
  }
}

// Application Insights & Log Analytics
module appInsights 'modules/appInsights.bicep' = {
  scope: resourceGroup
  name: 'appInsights'
  params: {
    location: location
    appInsightsName: appInsightsName
    logAnalyticsWorkspaceName: logAnalyticsName
    tags: tags
  }
}

// App Service Plan & Web App
module appService 'modules/appService.bicep' = {
  scope: resourceGroup
  name: 'appService'
  params: {
    location: location
    appServicePlanName: appServicePlanName
    webAppName: webAppName
    appServicePlanSku: appServicePlanSku
    containerRegistryLoginServer: containerRegistry.outputs.loginServer
    containerImageName: containerImageName
    appInsightsInstrumentationKey: appInsights.outputs.instrumentationKey
    appInsightsConnectionString: appInsights.outputs.connectionString
    tags: tags
  }
}

// Role Assignment: Grant AcrPull to Web App Managed Identity
module roleAssignments 'modules/roleAssignments.bicep' = {
  scope: resourceGroup
  name: 'roleAssignments'
  params: {
    containerRegistryId: containerRegistry.outputs.registryId
    principalId: appService.outputs.webAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Microsoft Foundry (Cognitive Services)
module foundry 'modules/foundry.bicep' = {
  scope: resourceGroup
  name: 'foundry'
  params: {
    location: location
    foundryName: foundryName
    skuName: foundrySku
    modelDeployments: foundryModelDeployments
    tags: tags
  }
}

// Outputs
output AZURE_LOCATION string = location
output AZURE_RESOURCE_GROUP string = resourceGroupName
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.registryName
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer
output AZURE_APP_SERVICE_NAME string = appService.outputs.webAppName
output AZURE_APP_SERVICE_URL string = 'https://${appService.outputs.webAppHostName}'
output APPINSIGHTS_INSTRUMENTATIONKEY string = appInsights.outputs.instrumentationKey
output APPINSIGHTS_CONNECTIONSTRING string = appInsights.outputs.connectionString
output AZURE_LOG_ANALYTICS_WORKSPACE_ID string = appInsights.outputs.logAnalyticsWorkspaceId
output AZURE_FOUNDRY_ENDPOINT string = foundry.outputs.foundryEndpoint
output AZURE_FOUNDRY_NAME string = foundry.outputs.foundryName
