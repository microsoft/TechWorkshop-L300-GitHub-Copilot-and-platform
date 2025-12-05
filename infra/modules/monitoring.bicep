targetScope = 'resourceGroup'

// ============================================================================
// PARAMETERS
// ============================================================================

@description('Base name for all resources')
param name string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Tags to apply to all resources')
param tags object = {}

@description('The retention period for Log Analytics data in days')
@minValue(30)
@maxValue(730)
param logAnalyticsRetentionDays int = 30

// ============================================================================
// VARIABLES
// ============================================================================

var resourceSuffix = take(uniqueString(subscription().id, resourceGroup().name, name), 6)
var logAnalyticsName = 'log-${name}-${resourceSuffix}'
var applicationInsightsName = 'appi-${name}-${resourceSuffix}'

// ============================================================================
// LOG ANALYTICS WORKSPACE
// ============================================================================

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: logAnalyticsRetentionDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1 // No cap for dev environment
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// ============================================================================
// APPLICATION INSIGHTS
// ============================================================================

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    RetentionInDays: 90
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

@description('The name of the Log Analytics workspace')
output logAnalyticsName string = logAnalytics.name

@description('The resource ID of the Log Analytics workspace')
output logAnalyticsResourceId string = logAnalytics.id

@description('The name of the Application Insights instance')
output applicationInsightsName string = applicationInsights.name

@description('The resource ID of the Application Insights instance')
output applicationInsightsResourceId string = applicationInsights.id

@description('The connection string for Application Insights')
output applicationInsightsConnectionString string = applicationInsights.properties.ConnectionString

@description('The instrumentation key for Application Insights')
output applicationInsightsInstrumentationKey string = applicationInsights.properties.InstrumentationKey
