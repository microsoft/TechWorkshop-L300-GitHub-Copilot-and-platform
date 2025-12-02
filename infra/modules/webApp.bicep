// Web App module
param name string
param location string
param serverFarmId string
param appSettings array
param identityType string = 'SystemAssigned'
resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: name
  location: location
  identity: {
    type: identityType
  }
  properties: {
    serverFarmId: serverFarmId
    siteConfig: {
      appSettings: appSettings
    }
    httpsOnly: true
  }
}
output webAppUrl string = webApp.properties.defaultHostName
