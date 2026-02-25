// Application Insights Module
// Provisions Application Insights for monitoring ZavaStorefront

@description('Name of the Application Insights instance')
param appInsightsName string

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Resource ID of the Log Analytics workspace')
param logAnalyticsId string

@description('Tags to apply to resources')
param tags object = {}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsId
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

output appInsightsId string = appInsights.id
output appInsightsName string = appInsights.name
output appInsightsConnectionString string = appInsights.properties.ConnectionString
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
