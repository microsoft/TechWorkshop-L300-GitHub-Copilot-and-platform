targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Name of the resource group')
param resourceGroupName string = ''

// Optional parameters for customization
@description('SKU for the App Service Plan')
param appServicePlanSku string = 'B1'

@description('SKU for the Container Registry')
param containerRegistrySku string = 'Standard'

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = uniqueString(subscription().id, location, environmentName)
var tags = {
  'azd-env-name': environmentName
}

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// User-Assigned Managed Identity
module identity './modules/identity.bicep' = {
  name: 'identity'
  scope: rg
  params: {
    name: '${abbrs.managedIdentityUserAssignedIdentities}${resourceToken}'
    location: location
    tags: tags
  }
}

// Log Analytics Workspace
module monitoring './modules/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    logAnalyticsName: '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsName: '${abbrs.insightsComponents}${resourceToken}'
    location: location
    tags: tags
  }
}

// Container Registry
module containerRegistry './modules/containerregistry.bicep' = {
  name: 'containerRegistry'
  scope: rg
  params: {
    name: '${abbrs.containerRegistryRegistries}${resourceToken}'
    location: location
    tags: tags
    sku: containerRegistrySku
    managedIdentityPrincipalId: identity.outputs.principalId
  }
}

// App Service
module appService './modules/appservice.bicep' = {
  name: 'appService'
  scope: rg
  params: {
    appServicePlanName: '${abbrs.webServerFarms}${resourceToken}'
    appServiceName: '${abbrs.webSitesAppService}${resourceToken}'
    location: location
    tags: tags
    sku: appServicePlanSku
    managedIdentityId: identity.outputs.id
    containerRegistryName: containerRegistry.outputs.name
    containerRegistryLoginServer: containerRegistry.outputs.loginServer
    applicationInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
  }
}

// Azure AI Services (Foundry)
module cognitiveServices './modules/cognitiveservices.bicep' = {
  name: 'cognitiveServices'
  scope: rg
  params: {
    name: '${abbrs.cognitiveServicesAccounts}${resourceToken}'
    location: location
    tags: tags
    managedIdentityPrincipalId: identity.outputs.principalId
    appServicePrincipalId: appService.outputs.systemAssignedIdentityPrincipalId
  }
}

// Outputs
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_SUBSCRIPTION_ID string = subscription().subscriptionId
output RESOURCE_GROUP_ID string = rg.id
output RESOURCE_GROUP_NAME string = rg.name
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer
output WEB_URI string = appService.outputs.uri
output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.applicationInsightsConnectionString
output AZURE_AI_SERVICES_ENDPOINT string = cognitiveServices.outputs.endpoint
