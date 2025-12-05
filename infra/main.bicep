// ============================================================================
// Main Bicep Template - ZavaStorefront Infrastructure
// ============================================================================
// Purpose: Orchestrate deployment of all Azure resources for ZavaStorefront
// Region: westus3
// Environment: dev (configurable via parameters)
// ============================================================================

targetScope = 'resourceGroup'

// ============================================================================
// Parameters
// ============================================================================

@description('Environment name (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environmentName string = 'dev'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Base name for resources')
param baseName string = 'zavastore'

@description('Tags for all resources')
param tags object = {}

@description('App Service Plan SKU')
param appServicePlanSku string = 'B1'

@description('Container Registry SKU')
@allowed(['Basic', 'Standard', 'Premium'])
param containerRegistrySku string = 'Basic'

@description('Log Analytics retention in days')
param logAnalyticsRetentionDays int = 30

@description('AI Services SKU')
@allowed(['S0', 'F0'])
param aiServicesSku string = 'S0'

@description('Container image name with tag')
param containerImage string = 'zavastore:latest'

// ============================================================================
// Variables
// ============================================================================

var resourceToken = toLower(uniqueString(subscription().id, resourceGroup().id, environmentName))
var abbrs = {
  containerRegistry: 'cr'
  appServicePlan: 'plan'
  webApp: 'app'
  logAnalytics: 'log'
  appInsights: 'appi'
  aiServices: 'ai'
}

// Resource names (following Azure naming conventions)
// Note: Resources with globally unique names include resourceToken for uniqueness
var containerRegistryName = '${abbrs.containerRegistry}${baseName}${resourceToken}'
var appServicePlanName = '${abbrs.appServicePlan}-${baseName}-${environmentName}-${resourceToken}'
var webAppName = '${abbrs.webApp}-${baseName}-${environmentName}-${resourceToken}'
var logAnalyticsName = '${abbrs.logAnalytics}-${baseName}-${environmentName}-${resourceToken}'
var appInsightsName = '${abbrs.appInsights}-${baseName}-${environmentName}-${resourceToken}'
var aiServicesName = '${abbrs.aiServices}-${baseName}-${environmentName}-${resourceToken}'
var aiServicesSubdomain = '${baseName}${resourceToken}'

// Common tags
var defaultTags = union(tags, {
  'azd-env-name': environmentName
  'azd-service-name': 'zavastore'
})

// Role definition IDs
var acrPullRoleId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

// ============================================================================
// Resources - Monitoring (deploy first)
// ============================================================================

module logAnalytics 'modules/log-analytics.bicep' = {
  name: 'logAnalytics'
  params: {
    name: logAnalyticsName
    location: location
    skuName: 'PerGB2018'
    retentionInDays: logAnalyticsRetentionDays
    tags: defaultTags
  }
}

module appInsights 'modules/app-insights.bicep' = {
  name: 'appInsights'
  params: {
    name: appInsightsName
    location: location
    logAnalyticsWorkspaceId: logAnalytics.outputs.resourceId
    applicationType: 'web'
    tags: defaultTags
  }
}

// ============================================================================
// Resources - Container Registry
// ============================================================================

module containerRegistry 'modules/container-registry.bicep' = {
  name: 'containerRegistry'
  params: {
    name: containerRegistryName
    location: location
    sku: containerRegistrySku
    tags: defaultTags
  }
}

// ============================================================================
// Resources - App Service
// ============================================================================

module appServicePlan 'modules/app-service-plan.bicep' = {
  name: 'appServicePlan'
  params: {
    name: appServicePlanName
    location: location
    skuName: appServicePlanSku
    tags: defaultTags
  }
}

module webApp 'modules/web-app.bicep' = {
  name: 'webApp'
  params: {
    name: webAppName
    location: location
    appServicePlanId: appServicePlan.outputs.resourceId
    acrLoginServer: containerRegistry.outputs.loginServer
    containerImage: containerImage
    appInsightsConnectionString: appInsights.outputs.connectionString
    tags: defaultTags
  }
}

// ============================================================================
// Resources - Role Assignments
// ============================================================================

module acrPullRoleAssignment 'modules/role-assignment.bicep' = {
  name: 'acrPullRoleAssignment'
  params: {
    principalId: webApp.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: acrPullRoleId
    scope: containerRegistry.outputs.resourceId
  }
}

// ============================================================================
// Resources - AI Services
// ============================================================================

module aiServices 'modules/ai-services.bicep' = {
  name: 'aiServices'
  params: {
    name: aiServicesName
    location: location
    kind: 'AIServices'
    skuName: aiServicesSku
    customSubDomainName: aiServicesSubdomain
    tags: defaultTags
    deployments: [
      {
        name: 'gpt-4o'
        model: {
          format: 'OpenAI'
          name: 'gpt-4o'
          version: '2024-11-20'
        }
        sku: {
          name: 'Standard'
          capacity: 10
        }
      }
    ]
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('The name of the resource group')
output AZURE_RESOURCE_GROUP string = resourceGroup().name

@description('The location of the resources')
output AZURE_LOCATION string = location

@description('The name of the Azure Container Registry')
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name

@description('The login server of the Azure Container Registry')
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer

@description('The name of the Web App')
output AZURE_WEB_APP_NAME string = webApp.outputs.name

@description('The URL of the Web App')
output AZURE_WEB_APP_URL string = 'https://${webApp.outputs.defaultHostname}'

@description('The Application Insights connection string')
output APPLICATIONINSIGHTS_CONNECTION_STRING string = appInsights.outputs.connectionString

@description('The AI Services endpoint')
output AZURE_AI_SERVICES_ENDPOINT string = aiServices.outputs.endpoint

@description('The AI Services resource name')
output AZURE_AI_SERVICES_NAME string = aiServices.outputs.name
