@description('Name of the Log Analytics Workspace')
param workspaceName string

@description('Location for the Log Analytics Workspace')
param location string = resourceGroup().location

@description('Tags to apply to the Log Analytics Workspace')
param tags object = {}

@description('SKU for the Log Analytics Workspace')
@allowed([
  'PerGB2018'
  'Free'
  'Standalone'
  'PerNode'
  'Standard'
  'Premium'
])
param sku string = 'PerGB2018'

@description('Data retention in days')
param retentionInDays int = 30

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
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

@description('The name of the Log Analytics Workspace')
output workspaceName string = logAnalyticsWorkspace.name

@description('The resource ID of the Log Analytics Workspace')
output workspaceId string = logAnalyticsWorkspace.id

@description('The customer ID of the Log Analytics Workspace')
output workspaceCustomerId string = logAnalyticsWorkspace.properties.customerId
