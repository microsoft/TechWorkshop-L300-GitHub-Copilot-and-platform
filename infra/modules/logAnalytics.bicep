// Log Analytics Workspace Module
// Required for Application Insights telemetry storage

@description('The name of the Log Analytics workspace')
param name string

@description('The location for the resource')
param location string = resourceGroup().location

@description('Tags for the resource')
param tags object = {}

@description('The SKU name for the Log Analytics workspace')
@allowed([
  'PerGB2018'
  'Free'
  'Standalone'
  'PerNode'
])
param skuName string = 'PerGB2018'

@description('The retention period for the logs in days')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      name: skuName
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

@description('The resource ID of the Log Analytics workspace')
output id string = logAnalyticsWorkspace.id

@description('The name of the Log Analytics workspace')
output name string = logAnalyticsWorkspace.name
