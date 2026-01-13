// Main Bicep template for ZavaStorefront infrastructure
targetScope = 'subscription'

@description('The environment name (e.g., dev, staging, prod)')
@minLength(1)
@maxLength(10)
param environmentName string = 'dev'

@description('The Azure region for all resources')
param location string = 'westus3'

@description('The base name for all resources')
param resourceBaseName string = 'zavastore'

@description('ACR SKU (Basic, Standard, or Premium)')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param acrSku string = 'Basic'

@description('App Service Plan SKU for Linux containers')
@allowed([
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1v2'
  'P2v2'
  'P3v2'
])
param appServicePlanSku string = 'B1'

@description('The Docker image to deploy (e.g., nginx:latest)')
param dockerImageName string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

@description('Tags to apply to all resources')
param tags object = {
  Environment: environmentName
  Application: 'ZavaStorefront'
  ManagedBy: 'Bicep'
}

// Generate consistent resource names
// Put environmentName at the end so azd can find it as a suffix
var resourceGroupName = 'rg-${resourceBaseName}-${location}-${environmentName}'
// Add resourceGroupName to uniqueString to make ACR name unique when RG changes
var acrName = replace('acr${resourceBaseName}${environmentName}${uniqueString(subscription().id, resourceGroupName)}', '-', '')
var appServicePlanName = 'asp-${resourceBaseName}-${location}-${environmentName}'
var appServiceName = 'app-${resourceBaseName}-${location}-${environmentName}'
var appInsightsName = 'appi-${resourceBaseName}-${location}-${environmentName}'
var logAnalyticsName = 'log-${resourceBaseName}-${location}-${environmentName}'
// Shorten foundry name to meet 32 character limit
var foundryName = 'ml-${take(resourceBaseName, 15)}-${take(uniqueString(subscription().id, location), 8)}'

// Create Resource Group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Deploy Log Analytics Workspace and Application Insights
module monitoring './modules/appinsights.bicep' = {
  scope: resourceGroup
  params: {
    location: location
    appInsightsName: appInsightsName
    logAnalyticsName: logAnalyticsName
    tags: tags
  }
}

// Deploy Azure Container Registry
module acr './modules/acr.bicep' = {
  scope: resourceGroup
  params: {
    location: location
    acrName: acrName
    acrSku: acrSku
    tags: tags
  }
}

// Deploy App Service Plan and Web App
module appService './modules/appservice.bicep' = {
  scope: resourceGroup
  params: {
    location: location
    appServicePlanName: appServicePlanName
    appServiceName: appServiceName
    appServicePlanSku: appServicePlanSku
    dockerImageName: dockerImageName
    acrLoginServer: acr.outputs.acrLoginServer
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString
    tags: tags
  }
}

// Deploy Microsoft Foundry
module foundry './modules/foundry.bicep' = {
  scope: resourceGroup
  params: {
    location: location
    foundryName: foundryName
    tags: tags
  }
}

// Assign AcrPull role to App Service managed identity
module roleAssignment './modules/roleassignments.bicep' = {
  scope: resourceGroup
  params: {
    acrName: acrName
    appServicePrincipalId: appService.outputs.appServiceManagedIdentityPrincipalId
  }
}

// Outputs
output resourceGroupName string = resourceGroupName
output acrName string = acrName
output acrLoginServer string = acr.outputs.acrLoginServer
output appServiceName string = appServiceName
output appServiceUrl string = appService.outputs.appServiceUrl
output appServiceManagedIdentityPrincipalId string = appService.outputs.appServiceManagedIdentityPrincipalId
output appInsightsName string = appInsightsName
output appInsightsInstrumentationKey string = monitoring.outputs.appInsightsInstrumentationKey
output foundryName string = foundryName
output location string = location
