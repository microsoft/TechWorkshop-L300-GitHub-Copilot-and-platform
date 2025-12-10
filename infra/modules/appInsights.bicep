// Application Insights module
// Creates Application Insights for monitoring and observability

@description('Application Insights name')
param appInsightsName string

@description('Azure region for the resource')
param location string

@description('Log Analytics Workspace ID')
param logAnalyticsWorkspaceId string

@description('Environment name')
param environment string

@description('Application Insights kind')
param kind string = 'web'

@description('Retention period in days')
param retentionInDays int = 90

@description('Sampling percentage')
param samplingPercentage int = 100

// Application Insights resource
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: kind
  tags: {
    environment: environment
    project: 'ZavaStorefront'
    managedBy: 'AZD'
  }
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceId
    RetentionInDays: retentionInDays
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    SamplingPercentage: samplingPercentage
  }
}

// Note: Metric alerts for CPU and Memory are omitted due to metric name variations across regions
// Users can configure custom alerts in the Azure Portal based on their specific needs

// Outputs
@description('Application Insights ID')
output appInsightsId string = appInsights.id

@description('Application Insights Instrumentation Key')
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey

@description('Application Insights Connection String')
output appInsightsConnectionString string = appInsights.properties.ConnectionString

@description('Application Insights Name')
output appInsightsName string = appInsights.name
