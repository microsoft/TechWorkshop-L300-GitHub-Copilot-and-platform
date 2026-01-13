// Application Insights module
param name string
param location string = resourceGroup().location
param workspaceResourceId string = ''

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspaceResourceId
  }
}

output appInsightsKey string = appInsights.properties.InstrumentationKey
output appInsightsId string = appInsights.id
