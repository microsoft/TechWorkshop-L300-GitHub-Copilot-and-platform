@description('Name of the App Service')
param appServiceName string

@description('Location for the App Service')
param location string = resourceGroup().location

@description('ID of the App Service Plan')
param appServicePlanId string

@description('ACR login server')
param acrLoginServer string

@description('Docker image name')
param dockerImageName string = 'simplestore'

@description('Docker image tag')
param dockerImageTag string = 'latest'

@description('Application Insights connection string')
param appInsightsConnectionString string

@description('ACR resource ID for role assignment')
param acrId string

@description('ACR name for role assignment')
param acrName string

// Reference existing ACR for role assignment
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

resource appService 'Microsoft.Web/sites@2022-09-01' = {
  name: appServiceName
  location: location
  kind: 'app,linux,container'
  tags: {
    'azd-service-name': 'app'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acrLoginServer}/${dockerImageName}:${dockerImageTag}'
      alwaysOn: false
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acrLoginServer}'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'WEBSITES_PORT'
          value: '80'
        }
      ]
    }
    httpsOnly: true
  }
}

// Assign AcrPull role to App Service managed identity
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(appService.id, acr.id, '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7f951dda-4ed3-4680-a7ca-43fe172d538d'
    ) // AcrPull role
    principalId: appService.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

output appServiceUrl string = 'https://${appService.properties.defaultHostName}'
output appServiceName string = appService.name
output appServiceId string = appService.id
output principalId string = appService.identity.principalId
