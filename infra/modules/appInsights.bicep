// Application Insights module
// Provides application performance monitoring and telemetry

@description('Name of the Application Insights instance')
param name string

@description('Location for the resource')
param location string = resourceGroup().location

@description('Tags for the resource')
param tags object = {}

@description('Resource ID of the Log Analytics workspace')
param logAnalyticsWorkspaceId string

@description('Application type')
@allowed([
  'web'
  'other'
])
param applicationType string = 'web'

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: applicationType
    WorkspaceResourceId: logAnalyticsWorkspaceId
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    RetentionInDays: 90
  }
}

@description('The resource ID of the Application Insights instance')
output id string = appInsights.id

@description('The name of the Application Insights instance')
output name string = appInsights.name

@description('The instrumentation key of the Application Insights instance')
output instrumentationKey string = appInsights.properties.InstrumentationKey

@description('The connection string of the Application Insights instance')
output connectionString string = appInsights.properties.ConnectionString
