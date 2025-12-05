targetScope = 'subscription'

@description('Environment name (e.g., dev, test, prod)')
@minLength(2)
@maxLength(10)
param environmentName string

@description('Primary location for all resources')
param location string = 'westus3'

@description('Application name')
param appName string = 'zavastore'

@description('Tags to apply to all resources')
param tags object = {
  Environment: environmentName
  Application: appName
  ManagedBy: 'Bicep'
}

// Generate unique resource names - following Azure naming conventions with proper length limits
var resourceGroupName = 'rg-${appName}-${environmentName}-${location}'
var uniqueSuffix = substring(uniqueString(subscription().id, resourceGroupName), 0, 4)
var acrName = '${appName}${environmentName}acr${uniqueSuffix}'  // e.g., zavadevacrxxxx (max 50 chars)
var appServicePlanName = '${appName}-${environmentName}-asp'  // e.g., zava-dev-asp
var webAppName = '${appName}-${environmentName}-web'  // e.g., zava-dev-web
var appInsightsName = '${appName}-${environmentName}-appi'  // e.g., zava-dev-appi
var foundryName = '${appName}-${environmentName}-cog-${uniqueSuffix}'  // e.g., zava-dev-cog-xxxx
var keyVaultName = '${appName}-${environmentName}-kv'  // e.g., zava-dev-kv (max 24 chars)
var logAnalyticsName = '${appName}-${environmentName}-law'  // e.g., zava-dev-law
var storageAccountName = '${appName}${environmentName}stg'  // e.g., zavadevstg (max 24 chars, lowercase)

// AcrPull role definition ID (built-in role)
var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

// Create resource group
resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Deploy Azure Container Registry
module acr './modules/acr.bicep' = {
  scope: rg
  name: 'acr-deployment'
  params: {
    acrName: acrName
    location: location
    sku: 'Basic'
    tags: tags
  }
}

// Deploy App Service Plan
module appServicePlan './modules/appServicePlan.bicep' = {
  scope: rg
  name: 'appServicePlan-deployment'
  params: {
    appServicePlanName: appServicePlanName
    location: location
    sku: 'B1'
    tags: tags
  }
}

// Deploy Log Analytics Workspace
module logAnalytics './modules/logAnalytics.bicep' = {
  scope: rg
  name: 'logAnalytics-deployment'
  params: {
    workspaceName: logAnalyticsName
    location: location
    sku: 'PerGB2018'
    retentionInDays: 30
    tags: tags
  }
}

// Deploy Application Insights (linked to Log Analytics)
module appInsights './modules/appInsights.bicep' = {
  scope: rg
  name: 'appInsights-deployment'
  params: {
    appInsightsName: appInsightsName
    location: location
    applicationType: 'web'
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    tags: tags
  }
}

// Deploy Key Vault
module keyVault './modules/keyVault.bicep' = {
  scope: rg
  name: 'keyVault-deployment'
  params: {
    keyVaultName: keyVaultName
    location: location
    sku: 'standard'
    tags: tags
  }
}

// Deploy Storage Account
module storageAccount './modules/storageAccount.bicep' = {
  scope: rg
  name: 'storageAccount-deployment'
  params: {
    storageAccountName: storageAccountName
    location: location
    sku: 'Standard_LRS'
    tags: tags
  }
}

// Deploy Web App
module webApp './modules/webApp.bicep' = {
  scope: rg
  name: 'webApp-deployment'
  params: {
    webAppName: webAppName
    location: location
    appServicePlanId: appServicePlan.outputs.appServicePlanId
    acrLoginServer: acr.outputs.acrLoginServer
    dockerImageName: 'zava-storefront:latest'
    appInsightsConnectionString: appInsights.outputs.connectionString
    tags: union(tags, {
      'azd-service-name': 'web'
    })
  }
}

// Deploy Azure AI Foundry
module foundry './modules/foundry.bicep' = {
  scope: rg
  name: 'foundry-deployment'
  params: {
    foundryName: foundryName
    location: location
    sku: 'S0'
    tags: tags
  }
}

// Assign AcrPull role to Web App's managed identity
module acrRoleAssignment './modules/roleAssignment.bicep' = {
  scope: rg
  name: 'acrRoleAssignment-deployment'
  params: {
    principalId: webApp.outputs.webAppPrincipalId
    roleDefinitionId: acrPullRoleDefinitionId
    targetResourceId: acr.outputs.acrId
    principalType: 'ServicePrincipal'
  }
}

// Outputs - AZD requires specific output names
@description('The name of the resource group - required by AZD')
output AZURE_RESOURCE_GROUP string = rg.name

@description('The name of the ACR')
output AZURE_CONTAINER_REGISTRY_NAME string = acr.outputs.acrName

@description('The login server of the ACR')
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = acr.outputs.acrLoginServer

@description('The name of the Web App - used by AZD for deployment')
output WEB_URI string = 'https://${webApp.outputs.webAppHostName}'

// Service-specific outputs for azd deploy (format: SERVICE_<servicename>_<property>)
output SERVICE_WEB_NAME string = webApp.outputs.webAppName
output SERVICE_WEB_RESOURCE_GROUP string = rg.name

@description('The name of Application Insights')
output AZURE_APPLICATION_INSIGHTS_NAME string = appInsights.outputs.appInsightsName

@description('The Application Insights connection string')
output APPLICATIONINSIGHTS_CONNECTION_STRING string = appInsights.outputs.connectionString

@description('The name of Azure AI Foundry')
output AZURE_COGNITIVE_SERVICES_NAME string = foundry.outputs.foundryName

@description('The endpoint of Azure AI Foundry')
output AZURE_COGNITIVE_SERVICES_ENDPOINT string = foundry.outputs.foundryEndpoint

@description('The name of the Key Vault')
output AZURE_KEY_VAULT_NAME string = keyVault.outputs.keyVaultName

@description('The name of the Log Analytics Workspace')
output AZURE_LOG_ANALYTICS_NAME string = logAnalytics.outputs.workspaceName

@description('The name of the Storage Account')
output AZURE_STORAGE_ACCOUNT_NAME string = storageAccount.outputs.storageAccountName
