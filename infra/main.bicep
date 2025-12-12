targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment')
param environmentName string

@description('Azure region for resources')
param location string

@description('Name of the resource group')
param resourceGroupName string = 'rg-${environmentName}'

// Create resource group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: {
    'azd-env-name': environmentName
  }
}

// Generate unique token for resource naming
var resourceToken = uniqueString(subscription().id, location, environmentName)
var appServiceName = 'app-${substring(resourceToken, 0, 12)}'
var appServicePlanName = 'plan-${substring(resourceToken, 0, 12)}'
var acrName = 'acr${substring(resourceToken, 0, 12)}'
var appInsightsName = 'appi-${substring(resourceToken, 0, 12)}'
var logAnalyticsName = 'law-${substring(resourceToken, 0, 12)}'

// Deploy Log Analytics workspace for monitoring
module logAnalyticsWorkspace 'modules/logAnalyticsWorkspace.bicep' = {
  scope: resourceGroup
  name: 'logAnalyticsWorkspace'
  params: {
    location: location
    workspaceName: logAnalyticsName
    environmentName: environmentName
  }
}

// Deploy Application Insights
module applicationInsights 'modules/applicationInsights.bicep' = {
  scope: resourceGroup
  name: 'applicationInsights'
  params: {
    location: location
    appInsightsName: appInsightsName
    workspaceId: logAnalyticsWorkspace.outputs.id
    environmentName: environmentName
  }
}

// Deploy App Service Plan
module appServicePlan 'modules/appServicePlan.bicep' = {
  scope: resourceGroup
  name: 'appServicePlan'
  params: {
    location: location
    appServicePlanName: appServicePlanName
    skuName: 'B1'
    environmentName: environmentName
  }
}

// Deploy Container Registry (before Web App so image reference exists)
module containerRegistry 'modules/containerRegistry.bicep' = {
  scope: resourceGroup
  name: 'containerRegistry'
  params: {
    location: location
    registryName: acrName
    environmentName: environmentName
  }
}

// Deploy App Service (Web App for Containers)
module appService 'modules/appService.bicep' = {
  scope: resourceGroup
  name: 'appService'
  params: {
    location: location
    appServiceName: appServiceName
    appServicePlanId: appServicePlan.outputs.id
    containerRegistryUrl: containerRegistry.outputs.loginServer
    dockerImageName: 'zavastorefont:latest'
    appInsightsConnectionString: applicationInsights.outputs.connectionString
    environmentName: environmentName
  }
}

// Assign AcrPull to the App Service managed identity
module acrRoleAssignment 'modules/acrRoleAssignment.bicep' = {
  scope: resourceGroup
  name: 'acrRoleAssignment'
  params: {
    containerRegistryName: containerRegistry.outputs.name
    principalId: appService.outputs.principalId
  }
}

@description('The resource ID of the created resource group')
output RESOURCE_GROUP_ID string = resourceGroup.id

@description('The resource group name')
output RESOURCE_GROUP_NAME string = resourceGroup.name

@description('The container registry endpoint')
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer

@description('The container registry name')
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name

@description('The App Service default hostname')
output AZURE_APP_SERVICE_HOSTNAME string = appService.outputs.defaultHostname

@description('The App Service name')
output AZURE_APP_SERVICE_NAME string = appService.outputs.name

@description('Application Insights connection string')
output APPLICATIONINSIGHTS_CONNECTION_STRING string = applicationInsights.outputs.connectionString
