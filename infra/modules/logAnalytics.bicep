// ============================================================================
// Log Analytics Workspace Module
// Provides centralized logging and monitoring for all Azure resources
// ============================================================================

@description('Name of the Log Analytics workspace')
param name string

@description('Location for the resource')
param location string = resourceGroup().location

@description('Tags to apply to the resource')
param tags object = {}

@description('SKU name for the workspace')
@allowed([
  'PerGB2018'
  'Free'
  'Standalone'
  'PerNode'
])
param skuName string = 'PerGB2018'

@description('Retention period in days (30-730)')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

// Deploy Log Analytics Workspace using Azure Verified Module
module logAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.9.1' = {
  name: 'logAnalyticsDeployment'
  params: {
    name: name
    location: location
    tags: tags
    skuName: skuName
    dataRetention: retentionInDays
  }
}

// Outputs
@description('The resource ID of the Log Analytics workspace')
output resourceId string = logAnalyticsWorkspace.outputs.resourceId

@description('The name of the Log Analytics workspace')
output name string = logAnalyticsWorkspace.outputs.name

@description('The location of the Log Analytics workspace')
output location string = logAnalyticsWorkspace.outputs.location
