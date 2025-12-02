// Log Analytics Workspace module
param name string
param location string
param retentionInDays int = 30
resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: name
  location: location
  properties: {
    retentionInDays: retentionInDays
  }
}
output lawId string = law.id
output lawWorkspaceId string = law.properties.customerId
