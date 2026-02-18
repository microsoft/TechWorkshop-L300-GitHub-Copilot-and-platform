// Main Bicep Orchestration Template
// Deploys all Azure resources for ZavaStorefront dev environment

targetScope = 'subscription'

@description('The environment name (e.g., dev, staging, prod)')
@minLength(2)
@maxLength(10)
param environmentName string = 'dev'

@description('The Azure region for all resources')
param location string = 'westus3'

@description('The SKU for the App Service Plan')
@allowed([
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
])
param appServiceSku string = 'B1'

@description('The SKU for Azure Container Registry')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param acrSku string = 'Basic'

@description('The container image name with tag')
param containerImage string = 'zavastore:latest'

// Generate unique resource names
var resourceToken = uniqueString(subscription().subscriptionId, environmentName, location)
var tags = {
  Environment: environmentName
  Project: 'ZavaStorefront'
  ManagedBy: 'Bicep'
}

// Resource names
var resourceGroupName = 'rg-zavastore-${environmentName}-${location}'
var acrName = 'acrzavastore${resourceToken}'
var appServicePlanName = 'asp-zavastore-${environmentName}-${location}'
var webAppName = 'app-zavastore-${environmentName}-${resourceToken}'
var appInsightsName = 'appi-zavastore-${environmentName}-${location}'
var logAnalyticsName = 'log-zavastore-${environmentName}-${location}'
var foundryName = 'mlw-zavastore-${environmentName}-${location}'
var storageAccountName = 'stzavastore${resourceToken}'
var keyVaultName = 'kv-zava-${resourceToken}'

// Create Resource Group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Deploy Azure Container Registry
module acr './modules/acr.bicep' = {
  name: 'acr-deployment'
  scope: resourceGroup
  params: {
    name: acrName
    location: location
    sku: acrSku
    tags: tags
  }
}

// Deploy Application Insights and Log Analytics
module monitoring './modules/app-insights.bicep' = {
  name: 'monitoring-deployment'
  scope: resourceGroup
  params: {
    workspaceName: logAnalyticsName
    appInsightsName: appInsightsName
    location: location
    tags: tags
  }
}

// Deploy App Service Plan and Web App
module appService './modules/app-service.bicep' = {
  name: 'app-service-deployment'
  scope: resourceGroup
  params: {
    appServicePlanName: appServicePlanName
    webAppName: webAppName
    location: location
    sku: appServiceSku
    acrLoginServer: acr.outputs.loginServer
    containerImage: containerImage
    appInsightsConnectionString: monitoring.outputs.connectionString
    tags: tags
  }
}

// Deploy Microsoft Foundry
module foundry './modules/foundry.bicep' = {
  name: 'foundry-deployment'
  scope: resourceGroup
  params: {
    name: foundryName
    location: location
    storageAccountName: storageAccountName
    keyVaultName: keyVaultName
    appInsightsId: monitoring.outputs.appInsightsId
    tags: tags
  }
}

// Assign AcrPull role to App Service managed identity
module roleAssignments './modules/role-assignments.bicep' = {
  name: 'role-assignments-deployment'
  scope: resourceGroup
  params: {
    principalId: appService.outputs.principalId
    acrId: acr.outputs.id
  }
}

// Outputs
@description('The name of the resource group')
output resourceGroupName string = resourceGroup.name

@description('The ACR login server URL')
output acrLoginServer string = acr.outputs.loginServer

@description('The ACR name')
output acrName string = acr.outputs.name

@description('The Web App URL')
output webAppUrl string = 'https://${appService.outputs.defaultHostname}'

@description('The Web App name')
output webAppName string = appService.outputs.name

@description('The Application Insights connection string')
output appInsightsConnectionString string = monitoring.outputs.connectionString

@description('The Foundry workspace name')
output foundryName string = foundry.outputs.name

@description('The Foundry discovery URL')
output foundryDiscoveryUrl string = foundry.outputs.discoveryUrl
