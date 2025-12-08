@description('Web App for Containers (Linux)')
param name string
param location string = resourceGroup().location
param serverFarmId string

resource site 'Microsoft.Web/sites@2021-02-01' = {
  name: name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: serverFarmId
    siteConfig: {
      linuxFxVersion: ''
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
      ]
    }
  }
}

output defaultHostname string = site.properties.defaultHostName
output principalId string = site.identity.principalId
output resourceId string = site.id
