@description('Name of the Application Insights resource')
param appInsightsName string

@description('Location for Application Insights')
param location string

@description('Log Analytics workspace ID')
param workspaceId string

@description('Environment name for tagging')
param environmentName string

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspaceId
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
  tags: {
    'azd-env-name': environmentName
  }
}

@description('The resource ID of Application Insights')
output id string = applicationInsights.id

@description('The name of Application Insights')
output name string = applicationInsights.name

@description('Application Insights connection string')
output connectionString string = applicationInsights.properties.ConnectionString

@description('Application Insights instrumentation key')
output instrumentationKey string = applicationInsights.properties.InstrumentationKey
