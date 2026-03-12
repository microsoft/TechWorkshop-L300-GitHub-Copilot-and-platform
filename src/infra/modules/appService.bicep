@description('App Service plan name.')
param appServicePlanName string

@description('Web App name.')
param webAppName string

@description('Azure location for App Service resources.')
param location string

@description('App Service plan SKU.')
param servicePlanSku string = 'B1'

@description('ACR login server name, for example: myregistry.azurecr.io.')
param acrLoginServer string

@description('Container image repository name inside ACR.')
param containerImageName string

@description('Container image tag to deploy.')
param containerImageTag string = 'latest'

@description('Application Insights connection string.')
param appInsightsConnectionString string

var linuxFxVersion = 'DOCKER|${acrLoginServer}/${containerImageName}:${containerImageTag}'
var planTier = startsWith(servicePlanSku, 'B') ? 'Basic' : 'Standard'

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  kind: 'linux'
  sku: {
    name: servicePlanSku
    tier: planTier
    size: servicePlanSku
    capacity: 1
  }
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      acrUseManagedIdentityCreds: true
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
      ]
    }
  }
}

output id string = webApp.id
output name string = webApp.name
output hostName string = webApp.properties.defaultHostName
output principalId string = webApp.identity.principalId!
