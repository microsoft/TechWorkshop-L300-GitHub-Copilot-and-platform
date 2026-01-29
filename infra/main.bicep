// =========================================================================
// ZavaStorefront Infrastructure - Main Orchestration
// =========================================================================
// This template deploys the complete infrastructure for the ZavaStorefront
// web application including containerized deployment, monitoring, and AI services.
// =========================================================================

targetScope = 'subscription'

// =========================================================================
// Parameters
// =========================================================================

@description('The environment name (e.g., dev, staging, prod)')
param environmentName string

@description('The Azure region for all resources')
param location string

@description('The principal ID of the current user for role assignments')
param principalId string = ''

@description('Tags to apply to all resources')
param tags object = {}

// =========================================================================
// Variables
// =========================================================================

var abbrs = loadJsonContent('abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

// Resource naming
var resourceGroupName = 'rg-${environmentName}-${location}'
var logAnalyticsName = '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
var appInsightsName = '${abbrs.insightsComponents}${resourceToken}'
var containerRegistryName = '${abbrs.containerRegistryRegistries}${replace(resourceToken, '-', '')}'
var appServicePlanName = '${abbrs.webServerFarms}${resourceToken}'
var webAppName = '${abbrs.webSitesAppService}${resourceToken}'
var aiServicesName = '${abbrs.cognitiveServicesAccounts}${resourceToken}'

// =========================================================================
// Resource Group
// =========================================================================

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: union(tags, {
    'azd-env-name': environmentName
  })
}

// =========================================================================
// Monitoring - Log Analytics Workspace
// =========================================================================

module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.11.1' = {
  name: 'logAnalyticsDeployment'
  scope: rg
  params: {
    name: logAnalyticsName
    location: location
    tags: tags
    skuName: 'PerGB2018'
    dataRetention: 30
  }
}

// =========================================================================
// Monitoring - Application Insights
// =========================================================================

module appInsights 'br/public:avm/res/insights/component:0.6.0' = {
  name: 'appInsightsDeployment'
  scope: rg
  params: {
    name: appInsightsName
    location: location
    tags: tags
    workspaceResourceId: logAnalytics.outputs.resourceId
    kind: 'web'
    applicationType: 'web'
  }
}

// =========================================================================
// Container Registry
// =========================================================================

module containerRegistry 'br/public:avm/res/container-registry/registry:0.9.1' = {
  name: 'containerRegistryDeployment'
  scope: rg
  params: {
    name: containerRegistryName
    location: location
    tags: tags
    acrSku: 'Standard'
    acrAdminUserEnabled: false
    // Role assignments for AcrPull will be added after web app is created
    roleAssignments: !empty(principalId) ? [
      {
        principalId: principalId
        principalType: 'User'
        roleDefinitionIdOrName: 'AcrPush'
      }
    ] : []
  }
}

// =========================================================================
// App Service Plan (Linux)
// =========================================================================

module appServicePlan 'br/public:avm/res/web/serverfarm:0.4.1' = {
  name: 'appServicePlanDeployment'
  scope: rg
  params: {
    name: appServicePlanName
    location: location
    tags: tags
    kind: 'linux'
    reserved: true
    skuName: 'B1'
    skuCapacity: 1
    zoneRedundant: false
  }
}

// =========================================================================
// Web App for Containers
// =========================================================================

module webApp 'br/public:avm/res/web/site:0.15.1' = {
  name: 'webAppDeployment'
  scope: rg
  params: {
    name: webAppName
    location: location
    tags: union(tags, {
      'azd-service-name': 'web'
    })
    kind: 'app,linux,container'
    serverFarmResourceId: appServicePlan.outputs.resourceId
    httpsOnly: true
    managedIdentities: {
      systemAssigned: true
    }
    siteConfig: {
      linuxFxVersion: 'DOCKER|mcr.microsoft.com/appsvc/staticsite:latest'
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      acrUseManagedIdentityCreds: true
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.outputs.connectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistry.outputs.loginServer}'
        }
        {
          name: 'DOCKER_ENABLE_CI'
          value: 'true'
        }
      ]
    }
    basicPublishingCredentialsPolicies: [
      {
        allow: false
        name: 'ftp'
      }
      {
        allow: false
        name: 'scm'
      }
    ]
  }
}

// =========================================================================
// ACR Pull Role Assignment for Web App
// =========================================================================

module acrPullRoleAssignment 'modules/acrRoleAssignment.bicep' = {
  name: 'acrPullRoleAssignmentDeployment'
  scope: rg
  params: {
    containerRegistryName: containerRegistry.outputs.name
    principalId: webApp.outputs.systemAssignedMIPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull
  }
}

// =========================================================================
// AI Services (Azure OpenAI / Cognitive Services)
// =========================================================================

module aiServices 'br/public:avm/res/cognitive-services/account:0.10.1' = {
  name: 'aiServicesDeployment'
  scope: rg
  params: {
    name: aiServicesName
    location: location
    tags: tags
    kind: 'AIServices'
    sku: 'S0'
    customSubDomainName: aiServicesName
    publicNetworkAccess: 'Enabled'
    deployments: [
      {
        name: 'gpt-4o'
        model: {
          format: 'OpenAI'
          name: 'gpt-4o'
          version: '2024-11-20'
        }
        sku: {
          name: 'GlobalStandard'
          capacity: 10
        }
      }
    ]
    roleAssignments: !empty(principalId) ? [
      {
        principalId: principalId
        principalType: 'User'
        roleDefinitionIdOrName: 'Cognitive Services OpenAI User'
      }
    ] : []
  }
}

// =========================================================================
// Outputs
// =========================================================================

@description('The name of the resource group')
output AZURE_RESOURCE_GROUP string = rg.name

@description('The Azure region where resources were deployed')
output AZURE_LOCATION string = location

@description('The name of the container registry')
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name

@description('The login server of the container registry')
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer

@description('The name of the web app')
output AZURE_WEB_APP_NAME string = webApp.outputs.name

@description('The default hostname of the web app')
output AZURE_WEB_APP_URL string = 'https://${webApp.outputs.defaultHostname}'

@description('The Application Insights connection string')
output APPLICATIONINSIGHTS_CONNECTION_STRING string = appInsights.outputs.connectionString

@description('The AI Services endpoint')
output AZURE_AISERVICES_ENDPOINT string = aiServices.outputs.endpoint

@description('The principal ID of the web app managed identity')
output AZURE_WEB_APP_PRINCIPAL_ID string = webApp.outputs.systemAssignedMIPrincipalId
