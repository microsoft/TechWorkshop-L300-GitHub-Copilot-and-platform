@description('Name of the Log Analytics workspace')
param workspaceName string

@description('Azure region for workspace deployment')
param location string

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

output workspaceResourceId string = logAnalytics.id
output workspaceName string = logAnalytics.name
