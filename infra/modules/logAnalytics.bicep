// Log Analytics Workspace for centralized logging
@description('The name of the Log Analytics workspace')
param workspaceName string

@description('The location for the Log Analytics workspace')
param location string = resourceGroup().location

@description('Tags to apply to the resource')
param tags object = {}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: 1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

@description('The resource ID of the Log Analytics workspace')
output workspaceId string = logAnalyticsWorkspace.id

@description('The customer ID (workspace ID) of the Log Analytics workspace')
output workspaceCustomerId string = logAnalyticsWorkspace.properties.customerId

@description('The name of the Log Analytics workspace')
output workspaceName string = logAnalyticsWorkspace.name
