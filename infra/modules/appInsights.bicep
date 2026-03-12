@description('Name of the Application Insights instance.')
param name string

@description('Azure region for the instance.')
param location string

@description('Resource ID of the Log Analytics workspace to link to.')
param logAnalyticsWorkspaceId string

@description('Resource tags.')
param tags object = {}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceId
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

@description('Application Insights connection string (preferred over instrumentation key).')
output connectionString string = appInsights.properties.ConnectionString

@description('Application Insights instrumentation key.')
output instrumentationKey string = appInsights.properties.InstrumentationKey

@description('Resource ID of the Application Insights instance.')
output id string = appInsights.id
