@description('Name of the Web App')
param name string

@description('Location for the resource')
param location string

@description('Resource ID of the App Service Plan')
param appServicePlanId string

@description('ACR login server URL')
param acrLoginServer string

@description('Docker image name and tag')
param dockerImageName string = 'zavastore:latest'

@description('Application Insights connection string')
param appInsightsConnectionString string

@description('Azure AI endpoint URL')
param aiEndpoint string = ''

@description('Tags to apply to the resource')
param tags object = {}

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: name
  location: location
  tags: tags
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acrLoginServer}/${dockerImageName}'
      acrUseManagedIdentityCreds: true
      alwaysOn: false
      ftpsState: 'Disabled'
      http20Enabled: true
      minTlsVersion: '1.2'
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
          name: 'AI_ENDPOINT'
          value: aiEndpoint
        }
      ]
    }
  }
}

@description('The resource ID of the Web App')
output id string = webApp.id

@description('The name of the Web App')
output name string = webApp.name

@description('The default hostname of the Web App')
output hostname string = webApp.properties.defaultHostName

@description('The principal ID of the Web App managed identity')
output principalId string = webApp.identity.principalId
