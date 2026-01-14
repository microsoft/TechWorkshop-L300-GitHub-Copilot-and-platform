// Log Analytics Workspace module
@description('Name of the Log Analytics workspace')
param name string

@description('Location for the Log Analytics workspace')
param location string

@description('Tags to apply to the resource')
param tags object = {}

@description('Data retention in days')
param retentionInDays int = 30

@description('SKU for the Log Analytics workspace')
param sku string = 'PerGB2018'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

output id string = logAnalytics.id
output name string = logAnalytics.name
output customerId string = logAnalytics.properties.customerId
