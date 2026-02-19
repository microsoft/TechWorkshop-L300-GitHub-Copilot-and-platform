targetScope = 'subscription'

@description('Name of the environment (e.g., dev, staging, prod)')
@minLength(1)
@maxLength(10)
param environmentName string

@description('Location for all resources')
param location string = 'westus3'

@description('Resource group name')
param resourceGroupName string = ''

@description('Application name prefix')
param appNamePrefix string = 'zavastore'

@description('Docker image name and tag')
param dockerImageAndTag string = 'zavastore:latest'

// Generate resource names based on naming conventions
var abbrs = {
  resourceGroup: 'rg'
  containerRegistry: 'cr'
  appServicePlan: 'asp'
  appService: 'app'
  logAnalytics: 'log'
  appInsights: 'appi'
  storageAccount: 'st'
  keyVault: 'kv'
  aiHub: 'aih'
}

var resourceToken = uniqueString(subscription().id, environmentName, location)
var tags = {
  environment: environmentName
  application: 'ZavaStorefront'
  managedBy: 'Bicep'
}

// Resource names
var rgName = !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourceGroup}-${appNamePrefix}-${environmentName}-${location}'
var acrName = '${abbrs.containerRegistry}${appNamePrefix}${environmentName}${resourceToken}'
var appServicePlanName = '${abbrs.appServicePlan}-${appNamePrefix}-${environmentName}-${location}'
var appServiceName = '${abbrs.appService}-${appNamePrefix}-${environmentName}-${location}'
var logAnalyticsName = '${abbrs.logAnalytics}-${appNamePrefix}-${environmentName}-${location}'
var appInsightsName = '${abbrs.appInsights}-${appNamePrefix}-${environmentName}-${location}'
var storageAccountName = '${abbrs.storageAccount}${appNamePrefix}${environmentName}${take(resourceToken, 8)}'
var keyVaultName = '${abbrs.keyVault}-${appNamePrefix}-${environmentName}-${take(resourceToken, 6)}'
var aiHubName = '${abbrs.aiHub}-${appNamePrefix}-${environmentName}-${location}'

// Create resource group
resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: rgName
  location: location
  tags: tags
}

// Deploy Log Analytics workspace
module logAnalytics './modules/logAnalytics.bicep' = {
  name: 'logAnalytics-deployment'
  scope: rg
  params: {
    logAnalyticsName: logAnalyticsName
    location: location
    sku: 'PerGB2018'
    retentionInDays: 30
    tags: tags
  }
}

// Deploy Application Insights
module appInsights './modules/appInsights.bicep' = {
  name: 'appInsights-deployment'
  scope: rg
  params: {
    appInsightsName: appInsightsName
    location: location
    workspaceId: logAnalytics.outputs.logAnalyticsId
    applicationType: 'web'
    tags: tags
  }
}

// Deploy Azure Container Registry
module acr './modules/acr.bicep' = {
  name: 'acr-deployment'
  scope: rg
  params: {
    acrName: acrName
    location: location
    sku: 'Basic'
    tags: tags
  }
}

// Deploy App Service Plan
module appServicePlan './modules/appServicePlan.bicep' = {
  name: 'appServicePlan-deployment'
  scope: rg
  params: {
    appServicePlanName: appServicePlanName
    location: location
    sku: 'B1'
    tags: tags
  }
}

// Deploy App Service
module appService './modules/appService.bicep' = {
  name: 'appService-deployment'
  scope: rg
  params: {
    appServiceName: appServiceName
    location: location
    appServicePlanId: appServicePlan.outputs.appServicePlanId
    acrLoginServer: acr.outputs.acrLoginServer
    dockerImageAndTag: dockerImageAndTag
    appInsightsConnectionString: appInsights.outputs.connectionString
    tags: tags
  }
}

// Deploy Storage Account for AI Hub
module storageAccount './modules/storageAccount.bicep' = {
  name: 'storageAccount-deployment'
  scope: rg
  params: {
    storageAccountName: storageAccountName
    location: location
    sku: 'Standard_LRS'
    tags: tags
  }
}

// Deploy Key Vault for AI Hub
module keyVault './modules/keyVault.bicep' = {
  name: 'keyVault-deployment'
  scope: rg
  params: {
    keyVaultName: keyVaultName
    location: location
    sku: 'standard'
    tags: tags
  }
}

// Deploy AI Hub (Microsoft Foundry)
module aiHub './modules/aiHub.bicep' = {
  name: 'aiHub-deployment'
  scope: rg
  params: {
    aiHubName: aiHubName
    location: location
    displayName: 'ZavaStorefront AI Hub'
    hubDescription: 'AI Hub for ZavaStorefront with GPT-4 and Phi models in ${location}'
    storageAccountId: storageAccount.outputs.storageAccountId
    keyVaultId: keyVault.outputs.keyVaultId
    appInsightsId: appInsights.outputs.appInsightsId
    tags: tags
  }
}

// Role assignment: Grant App Service managed identity AcrPull role on ACR
module acrRoleAssignment './modules/roleAssignment.bicep' = {
  name: 'acrRoleAssignment-deployment'
  scope: rg
  params: {
    principalId: appService.outputs.principalId
    roleDefinitionId: '7f951dda-4ed3-4680-a7ca-43fe172d538d' // AcrPull role
    targetResourceId: acr.outputs.acrId
  }
}

// Outputs
output resourceGroupName string = rg.name
output acrName string = acr.outputs.acrName
output acrLoginServer string = acr.outputs.acrLoginServer
output appServiceName string = appService.outputs.appServiceName
output appServiceHostName string = appService.outputs.appServiceHostName
output appInsightsName string = appInsights.outputs.appInsightsName
output aiHubName string = aiHub.outputs.aiHubName
output location string = location
