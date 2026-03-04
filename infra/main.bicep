targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment (used for resource naming)')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Tags to apply to all resources')
param tags object = {}

// AI model deployment parameters
@description('GPT-4 model deployment capacity (in thousands of tokens per minute)')
param gpt4Capacity int = 10

@description('Phi model deployment capacity (in thousands of tokens per minute)')
param phiCapacity int = 10

// Generate unique suffix for resource names
var abbrs = loadJsonContent('abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var resourceGroupName = '${abbrs.resourcesResourceGroups}${environmentName}'

// Tags for all resources
var allTags = union(tags, {
  'azd-env-name': environmentName
})

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: allTags
}

// Monitoring: Log Analytics + Application Insights
module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    name: '${abbrs.insightsComponents}${resourceToken}'
    logAnalyticsName: '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    location: location
    tags: allTags
  }
}

// Azure Container Registry
module acr 'modules/acr.bicep' = {
  name: 'acr'
  scope: rg
  params: {
    name: '${abbrs.containerRegistryRegistries}${resourceToken}'
    location: location
    tags: allTags
  }
}

// App Service Plan + App Service
module appService 'modules/app-service.bicep' = {
  name: 'app-service'
  scope: rg
  params: {
    name: '${abbrs.webSitesAppService}${resourceToken}'
    planName: '${abbrs.webServerFarms}${resourceToken}'
    location: location
    tags: union(allTags, {
      'azd-service-name': 'web'
    })
    applicationInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
    acrLoginServer: acr.outputs.loginServer
  }
}

// AcrPull role assignment for App Service managed identity
module acrPullRole 'modules/acr-role-assignment.bicep' = {
  name: 'acr-pull-role'
  scope: rg
  params: {
    acrName: acr.outputs.name
    principalId: appService.outputs.identityPrincipalId
  }
}

// AI Foundry: Azure AI Services + Model Deployments
module aiFoundry 'modules/ai-foundry.bicep' = {
  name: 'ai-foundry'
  scope: rg
  params: {
    name: '${abbrs.cognitiveServicesAccounts}${resourceToken}'
    hubName: 'hub-${resourceToken}'
    projectName: 'proj-${resourceToken}'
    location: location
    tags: allTags
    gpt4Capacity: gpt4Capacity
    phiCapacity: phiCapacity
  }
}

// Outputs for AZD
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP string = rg.name
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = acr.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = acr.outputs.name
output WEB_URI string = appService.outputs.uri
