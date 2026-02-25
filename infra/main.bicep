targetScope = 'subscription'

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

@minLength(1)
@maxLength(32)
@description('Name of the AZD environment (e.g. dev, staging). Used to generate a unique suffix for all resources.')
param environmentName string

@minLength(1)
@description('Primary Azure region for all resources.')
param location string

// ---------------------------------------------------------------------------
// Variables
// ---------------------------------------------------------------------------

var resourceSuffix = take(uniqueString(subscription().id, environmentName, location), 6)
var tags = { 'azd-env-name': environmentName }

// ---------------------------------------------------------------------------
// Resource Group
// ---------------------------------------------------------------------------

resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: 'rg-zavastore-${environmentName}-${location}'
  location: location
  tags: tags
}

// ---------------------------------------------------------------------------
// Modules
// ---------------------------------------------------------------------------

module acr './modules/acr.bicep' = {
  name: 'acr'
  scope: rg
  params: {
    name: 'acrzava${resourceSuffix}'
    location: location
    tags: tags
  }
}

module appInsights './modules/appinsights.bicep' = {
  name: 'appinsights'
  scope: rg
  params: {
    name: 'zava-${resourceSuffix}'
    location: location
    tags: tags
  }
}

module appService './modules/appservice.bicep' = {
  name: 'appservice'
  scope: rg
  params: {
    name: 'zava-${resourceSuffix}'
    location: location
    tags: tags
    acrLoginServer: acr.outputs.loginServer
    appInsightsConnectionString: appInsights.outputs.connectionString
  }
}

module roleAssignment './modules/roleassignment.bicep' = {
  name: 'roleassignment'
  scope: rg
  params: {
    acrName: acr.outputs.name
    webAppPrincipalId: appService.outputs.principalId
  }
}

module foundry './modules/foundry.bicep' = {
  name: 'foundry'
  scope: rg
  params: {
    name: 'aoai-zava-${resourceSuffix}'
    location: location
    tags: tags
  }
}

// ---------------------------------------------------------------------------
// Outputs — UPPERCASE names become azd environment variables
// ---------------------------------------------------------------------------

output AZURE_RESOURCE_GROUP string = rg.name
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = acr.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = acr.outputs.name
output AZURE_APP_SERVICE_NAME string = appService.outputs.name
output AZURE_APP_SERVICE_HOSTNAME string = appService.outputs.defaultHostname
output AZURE_FOUNDRY_ENDPOINT string = foundry.outputs.endpoint
output AZURE_FOUNDRY_NAME string = foundry.outputs.name
output AZURE_LOG_ANALYTICS_WORKSPACE_ID string = appInsights.outputs.logAnalyticsWorkspaceId
