@description('Name of the Log Analytics workspace.')
param workspaceName string

@description('Azure location for Log Analytics.')
param location string

@description('Retention period in days.')
param retentionInDays int = 30

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  properties: {
    retentionInDays: retentionInDays
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  }
}

output id string = workspace.id
output customerId string = workspace.properties.customerId
