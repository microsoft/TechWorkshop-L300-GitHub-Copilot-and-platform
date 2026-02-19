// Log Analytics Workspace module
param logAnalyticsName string
param location string
param skuName string = 'PerGB2018'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: skuName
    }
  }
}
// ...outputs, params, etc.
