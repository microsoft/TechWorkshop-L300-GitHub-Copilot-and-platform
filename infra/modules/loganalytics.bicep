// Log Analytics Workspace module
param resourceGroupName string
param location string
param environment string

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-12-01' = {
  name: 'zavastore-law-${environment}'
  location: location
  sku: {
    name: 'PerGB2018'
  }
  properties: {
    retentionInDays: 30
  }
}

output workspaceId string = logAnalytics.id
output workspaceName string = logAnalytics.name
