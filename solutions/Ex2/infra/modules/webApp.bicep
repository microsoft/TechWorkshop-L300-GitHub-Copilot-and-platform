// Web App Module (Linux Container)
@description('Name of the Web App')
param webAppName string

@description('Location for the Web App')
param location string = resourceGroup().location

@description('App Service Plan ID')
param appServicePlanId string

@description('ACR login server')
param acrLoginServer string

@description('Docker image name with tag')
param dockerImageName string = 'zavastore:latest'

@description('Application Insights Connection String')
param appInsightsConnectionString string = ''

@description('Tags for the resource')
param tags object = {}

resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  location: location
  kind: 'app,linux,container'
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acrLoginServer}/${dockerImageName}'
      alwaysOn: true
      appSettings: [
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acrLoginServer}'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'default'
        }
      ]
    }
  }
}

@description('The default hostname of the web app')
output defaultHostName string = webApp.properties.defaultHostName

@description('The principal ID of the system-assigned managed identity')
output principalId string = webApp.identity.principalId

@description('The resource ID of the web app')
output webAppId string = webApp.id

@description('The name of the web app')
output webAppName string = webApp.name
