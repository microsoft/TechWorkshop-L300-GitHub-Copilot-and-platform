@description('Application Insights resource name.')
param appInsightsName string

@description('Azure location for Application Insights.')
param location string

@description('Resource ID of the Log Analytics workspace.')
param workspaceResourceId string

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspaceResourceId
  }
}

output id string = appInsights.id
output connectionString string = appInsights.properties.ConnectionString
