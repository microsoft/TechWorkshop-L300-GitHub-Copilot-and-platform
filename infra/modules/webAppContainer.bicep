@description('Name of the Linux Web App')
param webAppName string

@description('Azure region for Web App')
param location string

@description('Resource ID of the Linux App Service Plan')
param appServicePlanId string

@description('Application Insights connection string')
param appInsightsConnectionString string

@description('ACR login server, for example contoso.azurecr.io')
param acrLoginServer string

@description('Container image in repo:tag format')
param containerImage string

@description('Linux worker runtime stack fallback')
param linuxFxVersion string

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    siteConfig: {
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'ASPNETCORE_URLS'
          value: 'http://+:8080'
        }
        {
          name: 'WEBSITES_PORT'
          value: '8080'
        }
        {
          name: 'DOTNET_RUNNING_IN_CONTAINER'
          value: 'true'
        }
      ]
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      acrUseManagedIdentityCreds: true
      linuxFxVersion: empty(containerImage) ? linuxFxVersion : 'DOCKER|${acrLoginServer}/${containerImage}'
    }
  }
}

output principalId string = webApp.identity.principalId
output webAppResourceId string = webApp.id
output defaultHostName string = webApp.properties.defaultHostName
