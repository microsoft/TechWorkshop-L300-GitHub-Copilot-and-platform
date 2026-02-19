@description('Name of the App Service (Web App)')
param appServiceName string

@description('Location for the App Service')
param location string = resourceGroup().location

@description('App Service Plan resource ID')
param appServicePlanId string

@description('ACR login server URL')
param acrLoginServer string

@description('Docker image name and tag')
param dockerImageAndTag string = 'zavastore:latest'

@description('Application Insights connection string')
param appInsightsConnectionString string = ''

@description('Tags to apply to the resource')
param tags object = {}

resource appService 'Microsoft.Web/sites@2022-09-01' = {
  name: appServiceName
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
      linuxFxVersion: 'DOCKER|${acrLoginServer}/${dockerImageAndTag}'
      acrUseManagedIdentityCreds: true // Use managed identity for ACR pull
      alwaysOn: false // Set to false for B1 SKU (not supported in Basic tier)
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
      ]
    }
  }
}

@description('The resource ID of the App Service')
output appServiceId string = appService.id

@description('The name of the App Service')
output appServiceName string = appService.name

@description('The default hostname of the App Service')
output appServiceHostName string = appService.properties.defaultHostName

@description('The principal ID of the system-assigned managed identity')
output principalId string = appService.identity.principalId
