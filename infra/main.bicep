// Main Bicep template for ZavaStorefront infrastructure
targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment (used for resource naming)')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Container image name and tag')
param containerImageName string = 'zava-storefront:latest'

// Generate unique resource names
var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = {
  'azd-env-name': environmentName
  application: 'ZavaStorefront'
  environment: 'dev'
}

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// Log Analytics Workspace
module logAnalytics './modules/logAnalytics.bicep' = {
  name: 'logAnalytics-deployment'
  scope: rg
  params: {
    workspaceName: '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    location: location
    tags: tags
  }
}

// Application Insights
module appInsights './modules/appInsights.bicep' = {
  name: 'appInsights-deployment'
  scope: rg
  params: {
    appInsightsName: '${abbrs.insightsComponents}${resourceToken}'
    location: location
    workspaceId: logAnalytics.outputs.workspaceId
    tags: tags
  }
}

// Azure Container Registry
module acr './modules/acr.bicep' = {
  name: 'acr-deployment'
  scope: rg
  params: {
    acrName: '${abbrs.containerRegistryRegistries}${resourceToken}'
    location: location
    sku: 'Basic'
    tags: tags
  }
}

// Azure OpenAI
module openai './modules/openai.bicep' = {
  name: 'openai-deployment'
  scope: rg
  params: {
    openAiName: '${abbrs.cognitiveServicesAccounts}${resourceToken}'
    location: location
    sku: 'S0'
    deployGpt4: true
    gpt4DeploymentName: 'gpt-4o'
    gpt4ModelName: 'gpt-4o'
    gpt4ModelVersion: '2024-11-20'
    gpt4Capacity: 10
    deployPhi: false
    phiDeploymentName: 'Phi-4'
    phiModelName: 'Phi-4'
    phiModelVersion: '7'
    phiCapacity: 1
    tags: tags
  }
}

// App Service Plan
module appServicePlan './modules/appServicePlan.bicep' = {
  name: 'appServicePlan-deployment'
  scope: rg
  params: {
    appServicePlanName: '${abbrs.webServerFarms}${resourceToken}'
    location: location
    sku: {
      name: 'B1'
      tier: 'Basic'
      size: 'B1'
      family: 'B'
      capacity: 1
    }
    tags: tags
  }
}

// Web App
module webApp './modules/webApp.bicep' = {
  name: 'webApp-deployment'
  scope: rg
  params: {
    webAppName: '${abbrs.webSitesAppService}${resourceToken}'
    location: location
    appServicePlanId: appServicePlan.outputs.appServicePlanId
    acrLoginServer: acr.outputs.loginServer
    applicationInsightsConnectionString: appInsights.outputs.connectionString
    openAiEndpoint: openai.outputs.openAiEndpoint
    gpt4DeploymentName: openai.outputs.gpt4DeploymentName
    phiDeploymentName: openai.outputs.phiDeploymentName
    containerImageName: containerImageName
    tags: union(tags, { 'azd-service-name': 'web' })
  }
}

// RBAC Role Assignments
module roleAssignments './modules/roleAssignments.bicep' = {
  name: 'roleAssignments-deployment'
  scope: rg
  params: {
    principalId: webApp.outputs.webAppPrincipalId
    acrId: acr.outputs.acrId
    openAiId: openai.outputs.openAiId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_SUBSCRIPTION_ID string = subscription().subscriptionId
output AZURE_RESOURCE_GROUP string = rg.name

output AZURE_CONTAINER_REGISTRY_ENDPOINT string = acr.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = acr.outputs.acrName

output AZURE_WEBAPP_NAME string = webApp.outputs.webAppName
output AZURE_WEBAPP_URL string = webApp.outputs.webAppUrl

output APPLICATIONINSIGHTS_CONNECTION_STRING string = appInsights.outputs.connectionString
output APPLICATIONINSIGHTS_NAME string = appInsights.outputs.applicationInsightsName

output AZURE_OPENAI_ENDPOINT string = openai.outputs.openAiEndpoint
output AZURE_OPENAI_NAME string = openai.outputs.openAiName
output AZURE_OPENAI_GPT4_DEPLOYMENT_NAME string = openai.outputs.gpt4DeploymentName
output AZURE_OPENAI_PHI_DEPLOYMENT_NAME string = openai.outputs.phiDeploymentName
