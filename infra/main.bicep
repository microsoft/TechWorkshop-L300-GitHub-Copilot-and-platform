param environmentName string
param location string = 'westus3'

var resourceToken = uniqueString(subscription().id, resourceGroup().id, location, environmentName)
var acrName = 'azacr${resourceToken}'

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
  }
}

module appServicePlan 'app-service-plan.bicep' = {
  name: 'appServicePlan'
  params: {
    environmentName: environmentName
    location: location
  }
}

module appInsights 'app-insights.bicep' = {
  name: 'appInsights'
  params: {
    environmentName: environmentName
    location: location
  }
}

module openAi 'azure-openai.bicep' = {
  name: 'openAi'
  params: {
    environmentName: environmentName
    location: location
  }
}

module webApp 'web-app.bicep' = {
  name: 'webApp'
  params: {
    environmentName: environmentName
    location: location
    appServicePlanId: appServicePlan.outputs.appServicePlanId
    acrLoginServer: acr.properties.loginServer
    appInsightsConnectionString: appInsights.outputs.appInsightsConnectionString
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, environmentName, 'acrpull')
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7f951dda-4ed3-4680-a7ca-43fe172d538d'
    )
    principalId: webApp.outputs.webAppIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output RESOURCE_GROUP_ID string = resourceGroup().id
output webAppUrl string = webApp.outputs.webAppUrl
