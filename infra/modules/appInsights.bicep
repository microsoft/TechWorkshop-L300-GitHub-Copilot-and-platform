@description('Application Insights name')
param name string

@description('Resource location')
param location string

@description('Log Analytics workspace resource ID')
param logAnalyticsWorkspaceId string

@description('If true, reference an existing App Insights instance')
param useExisting bool = false

// ─── Existing reference ───────────────────────────────────────
resource existing 'Microsoft.Insights/components@2020-02-02' existing = if (useExisting) {
  name: name
}

// ─── New resource ─────────────────────────────────────────────
resource appInsights 'Microsoft.Insights/components@2020-02-02' = if (!useExisting) {
  name: name
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceId
  }
}

output id string = useExisting ? existing.id : appInsights.id
output name string = useExisting ? existing.name : appInsights.name
output connectionString string = useExisting ? existing.properties.ConnectionString : appInsights.properties.ConnectionString
output instrumentationKey string = useExisting ? existing.properties.InstrumentationKey : appInsights.properties.InstrumentationKey
