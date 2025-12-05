@description('The name of the Log Analytics Workspace')
param workspaceName string

@description('The name of the Application Insights instance')
param appInsightsName string

@description('The location for the monitoring resources')
param location string = resourceGroup().location

@description('The retention in days for Log Analytics Workspace')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

@description('Tags to apply to the monitoring resources')
param tags object = {}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    RetentionInDays: retentionInDays
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    DisableLocalAuth: false
  }
}

@description('The resource ID of the Log Analytics Workspace')
output workspaceResourceId string = logAnalyticsWorkspace.id

@description('The name of the Log Analytics Workspace')
output workspaceName string = logAnalyticsWorkspace.name

@description('The resource ID of the Application Insights instance')
output appInsightsResourceId string = applicationInsights.id

@description('The name of the Application Insights instance')
output appInsightsName string = applicationInsights.name

@description('The connection string for Application Insights')
output appInsightsConnectionString string = applicationInsights.properties.ConnectionString

@description('The instrumentation key for Application Insights')
output appInsightsInstrumentationKey string = applicationInsights.properties.InstrumentationKey

@description('The location of the monitoring resources')
output location string = location
