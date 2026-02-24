targetScope = 'resourceGroup'

@minLength(1)
@maxLength(64)
@description('Name of the environment (e.g. dev, test, prod)')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string = 'westus3'

@description('Container image to deploy. Defaults to a placeholder; updated after first build.')
param containerImage string = 'mcr.microsoft.com/appsvc/staticsite:latest'

// Generate a unique token scoped to this subscription + environment + location
var resourceToken = toLower(uniqueString(resourceGroup().id, environmentName, location))

// Resource names — computed here so they can be referenced for role-assignment name/scope
var acrName = 'cr${resourceToken}'
var webAppName = 'app-${resourceToken}'

// AcrPull built-in role definition ID
var acrPullRoleId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

var tags = {
  'azd-env-name': environmentName
  environment: environmentName
}

// ---------------------------------------------------------------------------
// Log Analytics Workspace (backing store for Application Insights)
// ---------------------------------------------------------------------------
module logAnalytics './modules/logAnalytics.bicep' = {
  name: 'logAnalytics'
  params: {
    name: 'log-${resourceToken}'
    location: location
    tags: tags
  }
}

// ---------------------------------------------------------------------------
// Application Insights
// ---------------------------------------------------------------------------
module appInsights './modules/appInsights.bicep' = {
  name: 'appInsights'
  params: {
    name: 'appi-${resourceToken}'
    location: location
    tags: tags
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
  }
}

// ---------------------------------------------------------------------------
// Azure Container Registry (adminUserEnabled: false — RBAC pull only)
// ---------------------------------------------------------------------------
module acr './modules/acr.bicep' = {
  name: 'acr'
  params: {
    name: acrName
    location: location
    tags: tags
    sku: 'Basic'
  }
}

// ---------------------------------------------------------------------------
// App Service Plan + Linux Web App for Containers (system-assigned identity)
// ---------------------------------------------------------------------------
module appService './modules/appService.bicep' = {
  name: 'appService'
  params: {
    appServicePlanName: 'asp-${resourceToken}'
    webAppName: webAppName
    location: location
    tags: tags
    containerImage: '${acr.outputs.loginServer}/${containerImage}'
    acrLoginServer: acr.outputs.loginServer
    appInsightsConnectionString: appInsights.outputs.connectionString
    appInsightsInstrumentationKey: appInsights.outputs.instrumentationKey
  }
}

// ---------------------------------------------------------------------------
// AcrPull role assignment — Web App managed identity pulls images via RBAC
// Built-in AcrPull role: 7f951dda-4ed3-4680-a7ca-43fe172d538d
// Use locally-computed acrName/webAppName (known at deploy start) for name & scope.
// ---------------------------------------------------------------------------
resource acrExisting 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acrName, webAppName, acrPullRoleId)
  scope: acrExisting
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleId)
    principalId: appService.outputs.principalId
    principalType: 'ServicePrincipal'
  }
}

// ---------------------------------------------------------------------------
// Azure AI Foundry (Microsoft Foundry) — GPT-4 and Phi in westus3
// ---------------------------------------------------------------------------
module aiFoundry './modules/aiFoundry.bicep' = {
  name: 'aiFoundry'
  params: {
    name: 'aif-${resourceToken}'
    location: location
    tags: tags
  }
}

// ---------------------------------------------------------------------------
// Outputs consumed by AZD and application configuration
// ---------------------------------------------------------------------------
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = acr.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = acr.outputs.name
output AZURE_WEB_APP_NAME string = appService.outputs.name
output AZURE_WEB_APP_URL string = 'https://${appService.outputs.defaultHostname}'
output APPLICATIONINSIGHTS_CONNECTION_STRING string = appInsights.outputs.connectionString
output AZURE_AI_FOUNDRY_ENDPOINT string = aiFoundry.outputs.endpoint
output AZURE_AI_FOUNDRY_NAME string = aiFoundry.outputs.name
