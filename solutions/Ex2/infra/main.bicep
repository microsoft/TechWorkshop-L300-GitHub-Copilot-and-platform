// Main Bicep Template for ZavaStorefront Infrastructure
targetScope = 'subscription'

@description('Environment name (dev, staging, prod)')
@maxLength(10)
param environmentName string = 'dev'

@description('Primary location for all resources')
param location string = 'westus3'

@description('Application name')
param appName string = 'zavastore'

@description('Docker image tag')
param dockerImageTag string = 'latest'

@description('Enable Foundry deployment')
param enableFoundry bool = true

// Generate resource names
var resourceGroupName = 'rg-${appName}-${environmentName}-${location}'
var acrName = 'acr${appName}${environmentName}${uniqueString(subscription().subscriptionId, resourceGroupName)}'
var appServicePlanName = 'asp-${appName}-${environmentName}-${location}'
var webAppName = 'app-${appName}-${uniqueString(subscription().subscriptionId, resourceGroupName)}'
var appInsightsName = 'appi-${appName}-${environmentName}-${location}'
var aiFoundryName = 'oai-${appName}-${environmentName}-${location}'
var aiProjectName = '${aiFoundryName}-project'

// Tags for all resources
var tags = {
  Environment: environmentName
  Application: appName
  ManagedBy: 'Bicep'
}

// Create Resource Group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Deploy Azure Container Registry
module acr 'modules/acr.bicep' = {
  scope: resourceGroup
  name: 'acr-deployment'
  params: {
    acrName: acrName
    location: location
    sku: 'Basic'
    adminUserEnabled: false
    tags: tags
  }
}

// Deploy Application Insights
module appInsights 'modules/appInsights.bicep' = {
  scope: resourceGroup
  name: 'appinsights-deployment'
  params: {
    appInsightsName: appInsightsName
    location: location
    tags: tags
  }
}

// Deploy App Service Plan
module appServicePlan 'modules/appServicePlan.bicep' = {
  scope: resourceGroup
  name: 'appserviceplan-deployment'
  params: {
    appServicePlanName: appServicePlanName
    location: location
    sku: 'B1'
    tags: tags
  }
}

// Deploy Web App
module webApp 'modules/webApp.bicep' = {
  scope: resourceGroup
  name: 'webapp-deployment'
  params: {
    webAppName: webAppName
    location: location
    appServicePlanId: appServicePlan.outputs.appServicePlanId
    acrLoginServer: acr.outputs.loginServer
    dockerImageName: '${appName}:${dockerImageTag}'
    appInsightsConnectionString: appInsights.outputs.connectionString
    tags: tags
  }
}

// Assign AcrPull role to Web App's managed identity
module roleAssignment 'modules/roleAssignment.bicep' = {
  scope: resourceGroup
  name: 'roleassignment-deployment'
  params: {
    principalId: webApp.outputs.principalId
    roleDefinitionId: '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull
    acrName: acrName
  }
}

// Deploy Azure Foundry
module foundry 'modules/openai.bicep' = if (enableFoundry) {
  scope: resourceGroup
  name: 'foundry-deployment'
  params: {
    aiFoundryName: aiFoundryName
    aiProjectName: aiProjectName
    location: location
    deployments: [
      {
        name: 'gpt-5-mini'
        model: 'gpt-5-mini'
        version: '2025-08-07'
        format: 'OpenAI'
        capacity: 10
        sku: 'GlobalStandard'
      }
      {
        name: 'Phi-4'
        model: 'Phi-4'
        version: '7'
        format: 'Microsoft'
        capacity: 1
        sku: 'GlobalStandard'
      }
    ]
    tags: tags
  }
}

// Outputs
@description('The name of the resource group')
output resourceGroupName string = resourceGroupName

@description('The ACR login server')
output acrLoginServer string = acr.outputs.loginServer

@description('The ACR name')
output acrName string = acr.outputs.acrName

@description('The web app default hostname')
output webAppUrl string = 'https://${webApp.outputs.defaultHostName}'

@description('The web app name')
output webAppName string = webApp.outputs.webAppName

@description('The Application Insights connection string')
output appInsightsConnectionString string = appInsights.outputs.connectionString

@description('The Azure Foundry endpoint')
output foundryEndpoint string = enableFoundry ? foundry.outputs.endpoint : 'not-deployed'

// Additional outputs for azd environment variables
@description('The resource group name for azd')
output AZURE_RESOURCE_GROUP string = resourceGroupName

@description('The container registry name for azd')
output AZURE_CONTAINER_REGISTRY_NAME string = acr.outputs.acrName

@description('The container registry endpoint for azd')
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = acr.outputs.loginServer

@description('The web app name for azd')
output AZURE_WEBAPP_NAME string = webApp.outputs.webAppName
