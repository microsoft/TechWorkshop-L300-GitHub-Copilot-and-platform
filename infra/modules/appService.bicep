@description('Name of the App Service')
param appServiceName string

@description('Location for the App Service')
param location string

@description('App Service Plan ID')
param appServicePlanId string

@description('Container Registry login server URL')
param containerRegistryUrl string

@description('Docker image name and tag')
param dockerImageName string = 'zavastorefont:latest'

@description('Application Insights connection string')
param appInsightsConnectionString string = ''

@description('Environment name for tagging')
param environmentName string

resource appService 'Microsoft.Web/sites@2023-01-01' = {
  name: appServiceName
  location: location
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerRegistryUrl}/${dockerImageName}'
      acrUseManagedIdentityCreds: true
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'WEBSITES_PORT'
          value: '8080'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistryUrl}'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
      ]
      alwaysOn: true
      http20Enabled: true
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
    }
  }
  tags: {
    'azd-env-name': environmentName
    'azd-service-name': 'src'
  }
}

@description('The resource ID of the App Service')
output id string = appService.id

@description('The name of the App Service')
output name string = appService.name

@description('The default hostname of the App Service')
output defaultHostname string = appService.properties.defaultHostName

@description('The system-assigned managed identity principal ID')
output principalId string = appService.identity.principalId
