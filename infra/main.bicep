targetScope = 'resourceGroup'

// ── Parameters ───────────────────────────────────────────────────────────────

@description('Short environment name used to build resource names (e.g. dev, staging).')
@minLength(1)
@maxLength(10)
param environmentName string

@description('Azure region for all resources. westus3 is required for Foundry model availability.')
param location string = 'westus3'

@description('Optional name override for the Container Registry. Auto-generated if empty.')
param acrName string = ''

@description('Optional name override for the Web App. Auto-generated if empty.')
param appName string = ''

@description('Container image to deploy (e.g. myregistry.azurecr.io/zava-storefront:latest). Placeholder used on first provision.')
param containerImage string = 'mcr.microsoft.com/appsvc/staticsite:latest'

// ── Derived names ─────────────────────────────────────────────────────────────

var suffix = uniqueString(resourceGroup().id)

var resolvedAcrName    = !empty(acrName)    ? acrName    : 'acrzava${take(suffix, 8)}'
var resolvedAppName    = !empty(appName)    ? appName    : 'app-zava-${environmentName}-${take(suffix, 6)}'
var planName           = 'plan-zava-${environmentName}'
var logWorkspaceName   = 'log-zava-${environmentName}'
var appInsightsName    = 'appi-zava-${environmentName}'
var aiHubName          = 'hub-zava-${environmentName}'
var aiProjectName      = 'proj-zava-${environmentName}'

var tags = {
  environment: environmentName
  application: 'zava-storefront'
  'azd-env-name': environmentName
}

// ── Modules ───────────────────────────────────────────────────────────────────

module logAnalytics 'modules/logAnalytics.bicep' = {
  name: 'logAnalytics'
  params: {
    name: logWorkspaceName
    location: location
    tags: tags
  }
}

module acr 'modules/acr.bicep' = {
  name: 'acr'
  params: {
    name: resolvedAcrName
    location: location
    tags: tags
  }
}

module appServicePlan 'modules/appServicePlan.bicep' = {
  name: 'appServicePlan'
  params: {
    name: planName
    location: location
    tags: tags
  }
}

module appInsights 'modules/appInsights.bicep' = {
  name: 'appInsights'
  dependsOn: [logAnalytics]
  params: {
    name: appInsightsName
    location: location
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
    tags: tags
  }
}

module aiFoundry 'modules/aiFoundry.bicep' = {
  name: 'aiFoundry'
  params: {
    hubName: aiHubName
    projectName: aiProjectName
    location: location
    tags: tags
  }
}

module appService 'modules/appService.bicep' = {
  name: 'appService'
  dependsOn: [appServicePlan, appInsights, acr]
  params: {
    name: resolvedAppName
    location: location
    appServicePlanId: appServicePlan.outputs.id
    acrLoginServer: acr.outputs.loginServer
    containerImage: containerImage
    appInsightsConnectionString: appInsights.outputs.connectionString
    tags: tags
  }
}

// Role assignment depends on both the ACR and the Web App (for its managed identity principal ID)
module roleAssignment 'modules/roleAssignment.bicep' = {
  name: 'acrPullRoleAssignment'
  dependsOn: [acr, appService]
  params: {
    acrId: acr.outputs.id
    webAppPrincipalId: appService.outputs.principalId
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────

@description('Login server URL of the Container Registry.')
output acrLoginServer string = acr.outputs.loginServer

@description('Default hostname of the deployed Web App.')
output appServiceDefaultHostname string = appService.outputs.defaultHostname

@description('Application Insights connection string.')
output appInsightsConnectionString string = appInsights.outputs.connectionString

@description('AI Foundry project API endpoint.')
output aiFoundryEndpoint string = aiFoundry.outputs.projectEndpoint

@description('Name of the Web App (used in CI/CD image push).')
output appName string = appService.outputs.name

@description('Name of the Container Registry (used in CI/CD image build).')
output acrName string = acr.outputs.name
