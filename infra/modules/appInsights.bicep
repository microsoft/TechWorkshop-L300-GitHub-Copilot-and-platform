@description('Name of the Application Insights instance')
param appInsightsName string

@description('Location for Application Insights')
param location string = resourceGroup().location

@description('Tags to apply to Application Insights')
param tags object = {}

@description('Application type')
param applicationType string = 'web'

@description('Log Analytics Workspace ID to link Application Insights')
param logAnalyticsWorkspaceId string = ''

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: applicationType
  properties: {
    Application_Type: applicationType
    Request_Source: 'rest'
    WorkspaceResourceId: !empty(logAnalyticsWorkspaceId) ? logAnalyticsWorkspaceId : null
  }
}

@description('The name of Application Insights')
output appInsightsName string = appInsights.name

@description('The resource ID of Application Insights')
output appInsightsId string = appInsights.id

@description('The instrumentation key')
output instrumentationKey string = appInsights.properties.InstrumentationKey

@description('The connection string')
output connectionString string = appInsights.properties.ConnectionString
