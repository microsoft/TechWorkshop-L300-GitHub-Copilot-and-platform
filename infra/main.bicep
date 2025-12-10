// Main Bicep template for ZavaStorefront infrastructure deployment
// This template orchestrates all Azure resources for the development environment

targetScope = 'subscription'

@description('Environment name (dev, staging, prod)')
param environmentName string = 'dev'

@description('Azure region for resource deployment')
param location string = 'westus3'

@description('Prefix for resource naming')
param resourcePrefix string = 'zava-storefront'

@description('Container image name')
param containerImageName string = 'zavastorefront'

@description('Container image tag/version')
param containerImageTag string = 'latest'

@description('SKU for App Service Plan')
param appServicePlanSku string = 'B2'

@description('Instance count for App Service')
param appServiceInstanceCount int = 1

@description('Enable Key Vault for secrets management')
param enableKeyVault bool = true

// Variables
var resourceGroupName = 'rg-${resourcePrefix}-${environmentName}'
var uniqueSuffix = substring(uniqueString(subscription().id), 0, 5)
var acrName = replace('acr${resourcePrefix}${environmentName}${uniqueSuffix}', '-', '')
var appServicePlanName = 'asp-${resourcePrefix}-${environmentName}'
var appServiceName = 'app-${resourcePrefix}-${environmentName}'
var appInsightsName = 'appinsights-${resourcePrefix}-${environmentName}'
var logAnalyticsName = 'la-${resourcePrefix}-${environmentName}'
var keyVaultName = 'kv-${resourcePrefix}-${environmentName}'
var managedIdentityName = 'mi-${resourcePrefix}-${environmentName}'

// Create Resource Group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: {
    environment: environmentName
    project: 'ZavaStorefront'
    managedBy: 'AZD'
  }
}

// Create Log Analytics Workspace
module logAnalytics 'modules/logAnalytics.bicep' = {
  scope: resourceGroup
  name: 'logAnalyticsModule'
  params: {
    logAnalyticsName: logAnalyticsName
    location: location
    environment: environmentName
  }
}

// Create Application Insights
module appInsights 'modules/appInsights.bicep' = {
  scope: resourceGroup
  name: 'appInsightsModule'
  params: {
    appInsightsName: appInsightsName
    location: location
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsWorkspaceId
    environment: environmentName
  }
}

// Create Managed Identity for App Service
module managedIdentity 'modules/managedIdentity.bicep' = {
  scope: resourceGroup
  name: 'managedIdentityModule'
  params: {
    managedIdentityName: managedIdentityName
    location: location
    environment: environmentName
  }
}

// Create Container Registry
module acr 'modules/acr.bicep' = {
  scope: resourceGroup
  name: 'acrModule'
  params: {
    acrName: acrName
    location: location
    managedIdentityPrincipalId: managedIdentity.outputs.managedIdentityPrincipalId
    environment: environmentName
  }
}

// Create App Service Plan and App Service
module appService 'modules/appService.bicep' = {
  scope: resourceGroup
  name: 'appServiceModule'
  params: {
    appServicePlanName: appServicePlanName
    appServiceName: appServiceName
    location: location
    skuName: appServicePlanSku
    instanceCount: appServiceInstanceCount
    containerImageName: containerImageName
    containerImageTag: containerImageTag
    acrName: acrName
    managedIdentityId: managedIdentity.outputs.managedIdentityId
    managedIdentityClientId: managedIdentity.outputs.managedIdentityClientId
    appInsightsInstrumentationKey: appInsights.outputs.appInsightsInstrumentationKey
    appInsightsConnectionString: appInsights.outputs.appInsightsConnectionString
    environment: environmentName
  }
}

// Create Key Vault (optional)
module keyVault 'modules/keyVault.bicep' = if (enableKeyVault) {
  scope: resourceGroup
  name: 'keyVaultModule'
  params: {
    keyVaultName: keyVaultName
    location: location
    managedIdentityObjectId: managedIdentity.outputs.managedIdentityObjectId
    environment: environmentName
  }
}

// Outputs
@description('Resource Group Name')
output resourceGroupName string = resourceGroup.name

@description('Resource Group ID')
output resourceGroupId string = resourceGroup.id

@description('Container Registry URL')
output acrUrl string = acr.outputs.acrUrl

@description('App Service URL')
output appServiceUrl string = appService.outputs.appServiceUrl

@description('Application Insights Instrumentation Key')
output appInsightsInstrumentationKey string = appInsights.outputs.appInsightsInstrumentationKey

@description('Log Analytics Workspace ID')
output logAnalyticsWorkspaceId string = logAnalytics.outputs.logAnalyticsWorkspaceId

@description('Managed Identity Client ID')
output managedIdentityClientId string = managedIdentity.outputs.managedIdentityClientId

@description('Key Vault URI')
output keyVaultUri string = enableKeyVault ? keyVault.outputs.keyVaultUri : ''

@description('Deployment Summary')
output deploymentSummary object = {
  resourceGroup: resourceGroup.name
  region: location
  environment: environmentName
  containerRegistry: acrName
  appService: appServiceName
  appInsights: appInsightsName
  managedIdentity: managedIdentityName
}
