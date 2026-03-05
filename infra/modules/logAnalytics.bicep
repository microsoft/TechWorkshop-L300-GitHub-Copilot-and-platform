@description('Log Analytics workspace name')
param name string

@description('Resource location')
param location string

@description('If true, reference an existing workspace instead of creating one')
param useExisting bool = false

// ─── Existing reference ───────────────────────────────────────
resource existing 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = if (useExisting) {
  name: name
}

// ─── New resource ─────────────────────────────────────────────
resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = if (!useExisting) {
  name: name
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

output id string = useExisting ? existing.id : workspace.id
output name string = useExisting ? existing.name : workspace.name
