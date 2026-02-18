// Application Insights and Log Analytics Module
// Creates Log Analytics Workspace and Application Insights for monitoring

@description('The name of the Log Analytics Workspace')
param workspaceName string

@description('The name of the Application Insights instance')
param appInsightsName string

@description('The location for the resources')
param location string = resourceGroup().location

@description('Tags to apply to the resources')
param tags object = {}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
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
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

@description('The Application Insights instrumentation key')
output instrumentationKey string = appInsights.properties.InstrumentationKey

@description('The Application Insights connection string')
output connectionString string = appInsights.properties.ConnectionString

@description('The resource ID of the Application Insights instance')
output appInsightsId string = appInsights.id

@description('The resource ID of the Log Analytics Workspace')
output workspaceId string = logAnalyticsWorkspace.id
