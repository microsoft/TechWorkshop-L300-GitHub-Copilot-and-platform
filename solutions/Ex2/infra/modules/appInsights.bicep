// Application Insights Module
@description('Name of the Application Insights resource')
param appInsightsName string

@description('Location for Application Insights')
param location string = resourceGroup().location

@description('Log Analytics Workspace ID')
param workspaceId string = ''

@description('Tags for the resource')
param tags object = {}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  tags: tags
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: !empty(workspaceId) ? workspaceId : null
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

@description('The instrumentation key of Application Insights')
output instrumentationKey string = appInsights.properties.InstrumentationKey

@description('The connection string of Application Insights')
output connectionString string = appInsights.properties.ConnectionString

@description('The resource ID of Application Insights')
output appInsightsId string = appInsights.id

@description('The name of Application Insights')
output appInsightsName string = appInsights.name
