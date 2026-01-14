// Container Apps Environment module
param name string
param location string = resourceGroup().location
param logAnalyticsCustomerId string
param logAnalyticsSharedKey string

resource containerAppEnv 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: name
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsCustomerId
        sharedKey: logAnalyticsSharedKey
      }
    }
  }
}

output environmentId string = containerAppEnv.id
output environmentName string = containerAppEnv.name
