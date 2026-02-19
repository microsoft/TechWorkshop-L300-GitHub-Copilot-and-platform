@description('Name of the Application Insights instance')
param appInsightsName string

@description('Location for the Application Insights instance')
param location string = resourceGroup().location

@description('Log Analytics workspace ID to link with Application Insights')
param workspaceId string

@description('Application type')
@allowed([
  'web'
  'other'
])
param applicationType string = 'web'

@description('Tags to apply to the resource')
param tags object = {}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: applicationType
    WorkspaceResourceId: workspaceId
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

@description('The resource ID of the Application Insights instance')
output appInsightsId string = appInsights.id

@description('The name of the Application Insights instance')
output appInsightsName string = appInsights.name

@description('The instrumentation key of the Application Insights instance')
output instrumentationKey string = appInsights.properties.InstrumentationKey

@description('The connection string of the Application Insights instance')
output connectionString string = appInsights.properties.ConnectionString
