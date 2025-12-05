@description('Name of the Web App')
param webAppName string

@description('Location for the Web App')
param location string = resourceGroup().location

@description('App Service Plan ID')
param appServicePlanId string

@description('ACR login server')
param acrLoginServer string

@description('Docker image name and tag')
param dockerImageName string = 'zava-storefront:latest'

@description('Application Insights connection string')
param appInsightsConnectionString string

@description('Tags to apply to the Web App')
param tags object = {}

resource webApp 'Microsoft.Web/sites@2023-01-01' = {
  name: webAppName
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
      alwaysOn: true
      http20Enabled: true
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      acrUseManagedIdentityCreds: true
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
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'default'
        }
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Development'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acrLoginServer}'
        }
      ]
    }
  }
}

@description('The name of the Web App')
output webAppName string = webApp.name

@description('The resource ID of the Web App')
output webAppId string = webApp.id

@description('The default hostname of the Web App')
output webAppHostName string = webApp.properties.defaultHostName

@description('The principal ID of the Web App managed identity')
output webAppPrincipalId string = webApp.identity.principalId
