param environmentName string
param location string = resourceGroup().location
param appServicePlanId string
param acrLoginServer string
param appInsightsConnectionString string

var resourceToken = uniqueString(subscription().id, resourceGroup().id, location, environmentName)
var webAppName = 'azwa${resourceToken}'

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  tags: {
    'azd-service-name': 'ZavaStorefront'
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acrLoginServer}/zavastorefront:latest'
      appSettings: [
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acrLoginServer}'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
      ]
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

output webAppName string = webApp.name
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output webAppIdentityPrincipalId string = webApp.identity.principalId
