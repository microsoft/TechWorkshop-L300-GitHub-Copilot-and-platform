// Log Analytics Workspace Bicep Module
@description('Location for the Log Analytics workspace')
param location string
@description('Environment name (e.g., dev, prod)')
param environment string

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'log-${environment}'
  location: location
  properties: {
    retentionInDays: 30
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

output workspaceName string = logAnalytics.name
output workspaceId string = logAnalytics.id
output workspaceCustomerId string = logAnalytics.properties.customerId
