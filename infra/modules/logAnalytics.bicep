// Log Analytics Workspace module
// Creates workspace for centralized logging and analytics

@description('Log Analytics Workspace name')
param logAnalyticsName string

@description('Azure region for the resource')
param location string

@description('Environment name')
param environment string

@description('Log Analytics Workspace SKU')
param sku string = 'PerGB2018'

@description('Data retention in days')
param retentionInDays int = 30

// Log Analytics Workspace resource
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsName
  location: location
  tags: {
    environment: environment
    project: 'ZavaStorefront'
    managedBy: 'AZD'
  }
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: retentionInDays
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    features: {
      searchVersion: 1
      legacy: 0
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// Outputs
@description('Log Analytics Workspace ID')
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id

@description('Log Analytics Workspace Name')
output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.name

@description('Log Analytics Workspace Resource ID')
output logAnalyticsResourceId string = logAnalyticsWorkspace.id

@description('Log Analytics Customer ID')
output logAnalyticsCustomerId string = logAnalyticsWorkspace.properties.customerId
