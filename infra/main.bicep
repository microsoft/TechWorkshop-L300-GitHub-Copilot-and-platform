targetScope = 'resourceGroup'

@description('The environment name (e.g., dev, staging, prod)')
@minLength(1)
@maxLength(10)
param environmentName string = 'dev'

@description('The Azure region for all resources')
@metadata({
  azd: {
    type: 'location'
  }
})
param location string = 'westus3'

@description('The project name used for resource naming')
@minLength(1)
@maxLength(20)
param projectName string = 'ZavaStorefront'

@description('Tags to apply to all resources')
param tags object = {
  environment: environmentName
  project: projectName
  managedBy: 'Bicep'
}

// Variables for resource naming
var resourceToken = toLower(uniqueString(resourceGroup().id, environmentName, location))

// Role definition IDs (built-in Azure roles)
var acrPullRoleId = '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull

// Monitoring Module
module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring-${resourceToken}'
  params: {
    workspaceName: 'log-${toLower(projectName)}-${environmentName}-${resourceToken}'
    appInsightsName: 'appi-${toLower(projectName)}-${environmentName}-${resourceToken}'
    location: location
    retentionInDays: 30
    tags: tags
  }
}

// Container Registry Module
module containerRegistry 'modules/containerRegistry.bicep' = {
  name: 'acr-${resourceToken}'
  params: {
    name: 'acr${toLower(projectName)}${environmentName}${resourceToken}'
    location: location
    acrSku: 'Basic'
    acrAdminUserEnabled: false
    tags: tags
    roleAssignments: [] // Will be assigned after App Service is created
  }
}

// App Service Plan Module
module appServicePlan 'modules/appServicePlan.bicep' = {
  name: 'asp-${resourceToken}'
  params: {
    name: 'asp-${toLower(projectName)}-${environmentName}-${resourceToken}'
    location: location
    skuName: 'B1'
    skuCapacity: 1
    kind: 'linux'
    reserved: true
    tags: tags
  }
}

// App Service Module
module appService 'modules/appService.bicep' = {
  name: 'app-${resourceToken}'
  params: {
    name: 'app-${toLower(projectName)}-${environmentName}-${resourceToken}'
    location: location
    appServicePlanId: appServicePlan.outputs.resourceId
    dockerImage: '${containerRegistry.outputs.loginServer}/zava-storefront:latest'
    enableManagedIdentity: true
    httpsOnly: true
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString
    appInsightsInstrumentationKey: monitoring.outputs.appInsightsInstrumentationKey
    additionalAppSettings: [
      {
        name: 'DOCKER_REGISTRY_SERVER_URL'
        value: 'https://${containerRegistry.outputs.loginServer}'
      }
      {
        name: 'WEBSITES_PORT'
        value: '80'
      }
    ]
    tags: union(tags, {
      'azd-service-name': 'web'
    })
  }
}

// AI Foundry Module
module aiFoundry 'modules/aiFoundry.bicep' = {
  name: 'ai-${resourceToken}'
  params: {
    hubName: 'aihub-${environmentName}-${resourceToken}'
    projectName: 'aiproj-${environmentName}-${resourceToken}'
    location: location
    applicationInsightsId: monitoring.outputs.appInsightsResourceId
    containerRegistryId: containerRegistry.outputs.resourceId
    workspaceId: monitoring.outputs.workspaceResourceId
    tags: tags
  }
}

// Role Assignment: App Service -> ACR (AcrPull)
module acrPullRoleAssignment 'modules/containerRegistry.bicep' = {
  name: 'acr-role-${resourceToken}'
  params: {
    name: containerRegistry.outputs.name
    location: location
    acrSku: 'Basic'
    acrAdminUserEnabled: false
    tags: tags
    roleAssignments: [
      {
        principalId: appService.outputs.principalId
        roleDefinitionIdOrName: acrPullRoleId
        principalType: 'ServicePrincipal'
      }
    ]
  }
}

@description('The name of the resource group')
output resourceGroupName string = resourceGroup().name

@description('The location of the deployed resources')
output location string = location

@description('The App Service default hostname')
output appServiceHostname string = appService.outputs.defaultHostname

@description('The App Service URL')
output appServiceUrl string = 'https://${appService.outputs.defaultHostname}'

@description('The Container Registry login server')
output acrLoginServer string = containerRegistry.outputs.loginServer

@description('The Container Registry name')
output acrName string = containerRegistry.outputs.name

@description('The Application Insights connection string')
@secure()
output appInsightsConnectionString string = monitoring.outputs.appInsightsConnectionString

@description('The AI Foundry Hub name')
output aiHubName string = aiFoundry.outputs.hubName

@description('The AI Foundry Project name')
output aiProjectName string = aiFoundry.outputs.projectName

@description('Resource IDs for reference')
output resourceIds object = {
  resourceGroup: resourceGroup().id
  containerRegistry: containerRegistry.outputs.resourceId
  appServicePlan: appServicePlan.outputs.resourceId
  appService: appService.outputs.resourceId
  logAnalyticsWorkspace: monitoring.outputs.workspaceResourceId
  applicationInsights: monitoring.outputs.appInsightsResourceId
  aiHub: aiFoundry.outputs.hubResourceId
  aiProject: aiFoundry.outputs.projectResourceId
}
