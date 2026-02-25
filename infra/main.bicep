targetScope = 'resourceGroup'

@description('AZD environment name')
param environmentName string

@description('Azure location')
param location string

@description('Service name used by azd tags')
param serviceName string = 'zavastorefront'

@description('Container image repository name in ACR')
param imageName string = 'zavastorefront'

@description('Container image tag')
param imageTag string = 'latest'

@description('App Service plan SKU')
@allowed([
  'B1'
  'P1v3'
])
param appServicePlanSku string = 'B1'

@description('ACR SKU')
@allowed([
  'Basic'
  'Standard'
])
param acrSku string = 'Basic'

var resourceToken = uniqueString(subscription().id, resourceGroup().id, location, environmentName)
var acrName = 'azacr${resourceToken}'
var appServicePlanName = 'azasp${resourceToken}'
var webAppName = 'azweb${resourceToken}'
var workspaceName = 'azlog${resourceToken}'
var appInsightsName = 'azappi${resourceToken}'
var foundryName = 'azai${resourceToken}'
var userManagedIdentityName = 'azid${resourceToken}'

module managedIdentity './modules/managed-identity.bicep' = {
  name: 'managedIdentity'
  params: {
    name: userManagedIdentityName
    location: location
  }
}

module acr './modules/acr.bicep' = {
  name: 'acr'
  params: {
    name: acrName
    location: location
    sku: acrSku
  }
}

module appServicePlan './modules/appservice-plan.bicep' = {
  name: 'appServicePlan'
  params: {
    name: appServicePlanName
    location: location
    skuName: appServicePlanSku
  }
}

module appInsights './modules/appinsights.bicep' = {
  name: 'appInsights'
  params: {
    workspaceName: workspaceName
    appInsightsName: appInsightsName
    location: location
  }
}

module webApp './modules/webapp-container.bicep' = {
  name: 'webApp'
  params: {
    name: webAppName
    location: location
    appServicePlanId: appServicePlan.outputs.id
    acrLoginServer: acr.outputs.loginServer
    imageName: imageName
    imageTag: imageTag
    appInsightsConnectionString: appInsights.outputs.connectionString
    foundryEndpoint: foundry.outputs.endpoint
    serviceName: serviceName
    userManagedIdentityResourceId: managedIdentity.outputs.id
  }
}

module acrPullAssignment './modules/role-assignment-acrpull.bicep' = {
  name: 'acrPullAssignment'
  params: {
    acrName: acr.outputs.name
    principalId: webApp.outputs.systemPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  }
}

module foundry './modules/foundry.bicep' = {
  name: 'foundry'
  params: {
    name: foundryName
    location: location
  }
}

output RESOURCE_GROUP_ID string = resourceGroup().id
output ACR_NAME string = acrName
output WEB_APP_NAME string = webAppName
output APP_INSIGHTS_NAME string = appInsightsName
output FOUNDRY_NAME string = foundryName
