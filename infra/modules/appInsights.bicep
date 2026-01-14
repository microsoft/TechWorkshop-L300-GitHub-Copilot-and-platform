@description('Name of the Application Insights resource')
param appInsightsName string

@description('Location for Application Insights')
param location string = resourceGroup().location

@description('ID of the Log Analytics workspace')
param workspaceId string

@description('Application type')
param applicationType string = 'web'

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: applicationType
  properties: {
    Application_Type: applicationType
    WorkspaceResourceId: workspaceId
    Flow_Type: 'Bluefield'
    Request_Source: 'rest'
    RetentionInDays: 30
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

output instrumentationKey string = appInsights.properties.InstrumentationKey
output connectionString string = appInsights.properties.ConnectionString
output appInsightsId string = appInsights.id
output appInsightsName string = appInsights.name
