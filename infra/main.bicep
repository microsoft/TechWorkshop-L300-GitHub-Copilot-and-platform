targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment (e.g., dev, staging, prod)')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Name of the Azure AI Services account')
param aiServicesName string = ''

@description('Name of the App Service Plan')
param appServicePlanName string = ''

@description('Name of the Web App')
param webAppName string = ''

@description('Name of the Container Registry')
param containerRegistryName string = ''

@description('Name of the Log Analytics Workspace')
param logAnalyticsName string = ''

@description('Name of the Application Insights instance')
param applicationInsightsName string = ''

// Generate unique suffix for resource names
var resourceSuffix = take(uniqueString(subscription().id, environmentName, location), 6)
// ACR names must be alphanumeric only — strip hyphens from environment name
var acrSafeEnvName = replace(environmentName, '-', '')
var tags = {
  'azd-env-name': environmentName
}

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

// Monitoring (Log Analytics + Application Insights)
module monitoring './modules/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    tags: tags
    logAnalyticsName: !empty(logAnalyticsName) ? logAnalyticsName : 'log-${environmentName}-${resourceSuffix}'
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : 'appi-${environmentName}-${resourceSuffix}'
  }
}

// Container Registry
module containerRegistry './modules/container-registry.bicep' = {
  name: 'containerRegistry'
  scope: rg
  params: {
    location: location
    tags: tags
    containerRegistryName: !empty(containerRegistryName) ? containerRegistryName : 'cr${acrSafeEnvName}${resourceSuffix}'
  }
}

// App Service (Linux) with managed identity
module appService './modules/app-service.bicep' = {
  name: 'appService'
  scope: rg
  params: {
    location: location
    tags: tags
    appServicePlanName: !empty(appServicePlanName) ? appServicePlanName : 'plan-${environmentName}-${resourceSuffix}'
    webAppName: !empty(webAppName) ? webAppName : 'app-${environmentName}-${resourceSuffix}'
    containerRegistryLoginServer: containerRegistry.outputs.loginServer
    applicationInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
  }
}

// ACR Pull role assignment — App Service managed identity → Container Registry
module acrPullRole './modules/acr-pull-role.bicep' = {
  name: 'acrPullRole'
  scope: rg
  params: {
    containerRegistryName: containerRegistry.outputs.name
    principalId: appService.outputs.identityPrincipalId
  }
}

// Azure AI Foundry (AI Services)
module aiFoundry './modules/ai-foundry.bicep' = {
  name: 'aiFoundry'
  scope: rg
  params: {
    location: location
    tags: tags
    aiServicesName: !empty(aiServicesName) ? aiServicesName : 'ai-${environmentName}-${resourceSuffix}'
  }
}

// ============================================================================
// Outputs — UPPERCASE names become azd environment variables
// ============================================================================
output AZURE_RESOURCE_GROUP string = rg.name
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name
output AZURE_LOG_ANALYTICS_WORKSPACE_ID string = monitoring.outputs.logAnalyticsWorkspaceId
output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.applicationInsightsConnectionString
output AZURE_AI_SERVICES_ENDPOINT string = aiFoundry.outputs.endpoint
output WEB_URL string = appService.outputs.webAppUrl
