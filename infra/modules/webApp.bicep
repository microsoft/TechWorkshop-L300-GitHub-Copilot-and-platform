param name string
param location string
param serverFarmId string
param acrLoginServer string
param imageName string
param imageTag string
param applicationInsightsConnectionString string
param aiEndpoint string
param tags object = {}
param serviceName string = 'web'

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: name
  location: location
  kind: 'app,linux,container'
  tags: union(tags, {
    'azd-service-name': serviceName
  })
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    httpsOnly: true
    serverFarmId: serverFarmId
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acrLoginServer}/${imageName}:${imageTag}'
      acrUseManagedIdentityCreds: true
      alwaysOn: false
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'WEBSITES_PORT'
          value: '8080'
        }
        {
          name: 'ASPNETCORE_URLS'
          value: 'http://+:8080'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsightsConnectionString
        }
        {
          name: 'AZURE_AI_FOUNDRY_ENDPOINT'
          value: aiEndpoint
        }
      ]
    }
  }
}

output id string = webApp.id
output name string = webApp.name
output principalId string = webApp.identity.principalId
output url string = 'https://${webApp.properties.defaultHostName}'
