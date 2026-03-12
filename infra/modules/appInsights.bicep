@description('Name of the Application Insights component')
param appInsightsName string

@description('Azure region for Application Insights')
param location string

@description('Resource ID of the Log Analytics workspace')
param workspaceResourceId string

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspaceResourceId
    IngestionMode: 'LogAnalytics'
    DisableLocalAuth: true
  }
}

output appInsightsResourceId string = appInsights.id
output connectionString string = appInsights.properties.ConnectionString
