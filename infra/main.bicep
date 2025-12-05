targetScope = 'subscription'

// Parameters
@description('Environment name (e.g., dev, test, prod)')
param environmentName string = 'dev'

@description('Location for all resources')
param location string = 'swedencentral'

@description('Unique identifier for resource naming')
param uniqueId string = uniqueString(subscription().subscriptionId, environmentName)

@description('Application name')
param applicationName string = 'zavastore'

// Variables
var resourceGroupName = 'rg-${applicationName}-${environmentName}-${location}'
var tags = {
  Environment: environmentName
  Application: applicationName
  ManagedBy: 'AzureDeveloperCLI'
}

// Create Resource Group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Deploy Log Analytics Workspace
module logAnalytics 'modules/logAnalytics.bicep' = {
  name: 'logAnalytics-deployment'
  scope: resourceGroup
  params: {
    location: location
    logAnalyticsName: 'log-${applicationName}-${environmentName}-${location}'
    tags: tags
  }
}

// Deploy Application Insights
module appInsights 'modules/appInsights.bicep' = {
  name: 'appInsights-deployment'
  scope: resourceGroup
  params: {
    location: location
    appInsightsName: 'appi-${applicationName}-${environmentName}-${location}'
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    tags: tags
  }
}

// Deploy Azure Container Registry
module acr 'modules/acr.bicep' = {
  name: 'acr-deployment'
  scope: resourceGroup
  params: {
    location: location
    acrName: 'acr${uniqueId}${applicationName}${environmentName}'
    tags: tags
  }
}

// Deploy App Service Plan and App Service
module appService 'modules/appService.bicep' = {
  name: 'appService-deployment'
  scope: resourceGroup
  params: {
    location: location
    appServicePlanName: 'plan-${applicationName}-${environmentName}-${location}'
    appServiceName: 'app-${applicationName}-${environmentName}-${uniqueId}'
    acrLoginServer: acr.outputs.loginServer
    acrName: acr.outputs.name
    appInsightsConnectionString: appInsights.outputs.connectionString
    tags: tags
  }
}

// Deploy Role Assignments
module roleAssignments 'modules/roleAssignments.bicep' = {
  name: 'roleAssignments-deployment'
  scope: resourceGroup
  params: {
    appServicePrincipalId: appService.outputs.principalId
    acrResourceId: acr.outputs.resourceId
  }
}

// Deploy Microsoft Foundry (AI Platform)
module foundry 'modules/foundry.bicep' = {
  name: 'foundry-deployment'
  scope: resourceGroup
  params: {
    location: location
    foundryName: 'foundry-${applicationName}-${environmentName}-${location}'
    tags: tags
  }
}

// Outputs
output resourceGroupName string = resourceGroup.name
output appServiceUrl string = appService.outputs.defaultHostName
output acrLoginServer string = acr.outputs.loginServer
output appInsightsConnectionString string = appInsights.outputs.connectionString
output logAnalyticsWorkspaceId string = logAnalytics.outputs.workspaceId
