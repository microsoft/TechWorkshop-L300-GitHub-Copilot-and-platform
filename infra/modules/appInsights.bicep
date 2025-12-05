// Application Insights Module
// For application monitoring and telemetry

@description('The name of the Application Insights resource')
param name string

@description('The location for the resource')
param location string = resourceGroup().location

@description('Tags for the resource')
param tags object = {}

@description('The resource ID of the Log Analytics workspace')
param workspaceResourceId string

@description('The type of application being monitored')
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
    WorkspaceResourceId: workspaceResourceId
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

@description('The resource ID of the Application Insights resource')
output id string = appInsights.id

@description('The name of the Application Insights resource')
output name string = appInsights.name

@description('The instrumentation key for Application Insights')
output instrumentationKey string = appInsights.properties.InstrumentationKey

@description('The connection string for Application Insights')
output connectionString string = appInsights.properties.ConnectionString
