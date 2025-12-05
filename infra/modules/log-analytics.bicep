// ============================================================================
// Log Analytics Workspace Module
// ============================================================================
// Purpose: Deploy Log Analytics workspace for centralized logging
// Usage: Required by Application Insights for data storage
// ============================================================================

@description('The name of the Log Analytics workspace')
param name string

@description('Location for the resource')
param location string = resourceGroup().location

@description('SKU name for the Log Analytics workspace')
@allowed(['Free', 'PerGB2018', 'PerNode', 'Premium', 'Standalone', 'Standard'])
param skuName string = 'PerGB2018'

@description('Data retention in days')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

@description('Tags for the resource')
param tags object = {}

// ============================================================================
// Resources
// ============================================================================

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
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
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('The resource ID of the Log Analytics workspace')
output resourceId string = logAnalyticsWorkspace.id

@description('The name of the Log Analytics workspace')
output name string = logAnalyticsWorkspace.name

@description('The workspace ID (customer ID) of the Log Analytics workspace')
output workspaceId string = logAnalyticsWorkspace.properties.customerId
