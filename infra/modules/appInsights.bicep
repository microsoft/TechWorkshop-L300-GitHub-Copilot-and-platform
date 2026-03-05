@description('Name of the Application Insights resource')
param appInsightsName string

@description('Name of the Log Analytics Workspace')
param logAnalyticsName string

@description('Location for the resources')
param location string

@description('Tags to apply to the resources')
param tags object = {}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

@description('The resource ID of Application Insights')
output appInsightsId string = appInsights.id

@description('The name of Application Insights')
output appInsightsName string = appInsights.name

@description('The connection string for Application Insights')
output connectionString string = appInsights.properties.ConnectionString

@description('The instrumentation key for Application Insights')
output instrumentationKey string = appInsights.properties.InstrumentationKey

@description('The resource ID of the Log Analytics Workspace')
output logAnalyticsId string = logAnalyticsWorkspace.id
