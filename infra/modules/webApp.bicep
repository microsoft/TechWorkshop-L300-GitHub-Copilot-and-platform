// Web App for Containers (Linux) module
param name string
param location string = resourceGroup().location
param planId string
param acrLoginServer string
param imageName string
param managedIdentityId string
param appInsightsKey string

resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: planId
    siteConfig: {
      linuxFxVersion: 'DOCKER|' + acrLoginServer + '/' + imageName
    }
    appSettings: [
      {
        name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
        value: appInsightsKey
      }
    ]
  }
}

output webAppId string = webApp.id
output webAppName string = webApp.name
output webAppIdentityPrincipalId string = webApp.identity.principalId
