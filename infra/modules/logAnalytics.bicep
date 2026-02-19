@description('Name of the Log Analytics workspace')
param logAnalyticsName string

@description('Location for the Log Analytics workspace')
param location string = resourceGroup().location

@description('SKU for the Log Analytics workspace')
@allowed([
  'PerGB2018'
  'Free'
  'Standalone'
  'PerNode'
  'Standard'
  'Premium'
])
param sku string = 'PerGB2018'

@description('Retention period in days')
param retentionInDays int = 30

@description('Tags to apply to the resource')
param tags object = {}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: retentionInDays
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

@description('The resource ID of the Log Analytics workspace')
output logAnalyticsId string = logAnalytics.id

@description('The name of the Log Analytics workspace')
output logAnalyticsName string = logAnalytics.name

@description('The customer ID (workspace ID) of the Log Analytics workspace')
output customerId string = logAnalytics.properties.customerId
