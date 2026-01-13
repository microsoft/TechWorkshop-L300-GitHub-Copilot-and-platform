// Managed Identity module (System Assigned)
param webAppName string
param location string = resourceGroup().location

resource webApp 'Microsoft.Web/sites@2022-03-01' existing = {
  name: webAppName
}

output principalId string = webApp.identity.principalId
