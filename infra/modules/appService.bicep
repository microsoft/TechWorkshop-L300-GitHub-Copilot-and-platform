@description('The name of the App Service')
param name string

@description('The location for the App Service')
param location string

@description('Tags to apply to the resource')
param tags object = {}

@description('The resource ID of the App Service Plan')
param appServicePlanId string

@description('The name of the container registry')
param containerRegistryName string

@description('Application Insights connection string')
@secure()
param applicationInsightsConnectionString string

@description('Application Insights instrumentation key')
@secure()
param applicationInsightsInstrumentationKey string

@description('Docker image and tag')
param dockerImageAndTag string = 'mcr.microsoft.com/appsvc/staticsite:latest'

resource appService 'Microsoft.Web/sites@2023-12-01' = {
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
      linuxFxVersion: 'DOCKER|${dockerImageAndTag}'
      alwaysOn: false
      http20Enabled: true
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistryName}.azurecr.io'
        }
        {
          name: 'DOCKER_ENABLE_CI'
          value: 'true'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsightsInstrumentationKey
        }
      ]
      acrUseManagedIdentityCreds: true
    }
  }
}

output id string = appService.id
output name string = appService.name
output principalId string = appService.identity.principalId
output url string = 'https://${appService.properties.defaultHostName}'
output defaultHostName string = appService.properties.defaultHostName
