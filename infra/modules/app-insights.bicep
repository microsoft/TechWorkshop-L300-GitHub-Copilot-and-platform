// ============================================================================
// Application Insights Module
// ============================================================================
// Purpose: Deploy Application Insights for application monitoring
// Requirement: Requires Log Analytics workspace for data storage
// ============================================================================

@description('The name of the Application Insights resource')
param name string

@description('Location for the resource')
param location string = resourceGroup().location

@description('Resource ID of the Log Analytics workspace')
param logAnalyticsWorkspaceId string

@description('Application type')
@allowed(['web', 'other'])
param applicationType string = 'web'

@description('Tags for the resource')
param tags object = {}

// ============================================================================
// Resources
// ============================================================================

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  tags: tags
  kind: applicationType
  properties: {
    Application_Type: applicationType
    WorkspaceResourceId: logAnalyticsWorkspaceId
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('The resource ID of the Application Insights resource')
output resourceId string = appInsights.id

@description('The name of the Application Insights resource')
output name string = appInsights.name

@description('The instrumentation key of the Application Insights resource')
output instrumentationKey string = appInsights.properties.InstrumentationKey

@description('The connection string of the Application Insights resource')
output connectionString string = appInsights.properties.ConnectionString
