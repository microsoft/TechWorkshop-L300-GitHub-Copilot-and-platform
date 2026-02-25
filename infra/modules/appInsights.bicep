// Application Insights for application monitoring
@description('The name of the Application Insights resource')
param appInsightsName string

@description('The location for the Application Insights resource')
param location string = resourceGroup().location

@description('The resource ID of the Log Analytics workspace')
param workspaceId string

@description('Tags to apply to the resource')
param tags object = {}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspaceId
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

@description('The resource ID of the Application Insights instance')
output applicationInsightsId string = applicationInsights.id

@description('The instrumentation key for Application Insights')
output instrumentationKey string = applicationInsights.properties.InstrumentationKey

@description('The connection string for Application Insights')
output connectionString string = applicationInsights.properties.ConnectionString

@description('The name of the Application Insights instance')
output applicationInsightsName string = applicationInsights.name
