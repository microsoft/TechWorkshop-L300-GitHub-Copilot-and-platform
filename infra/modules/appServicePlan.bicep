@description('App Service Plan name')
param name string

@description('Resource location')
param location string

@description('If true, reference an existing App Service Plan')
param useExisting bool = false

@description('App Service Plan SKU')
param skuName string = 'B1'

// ─── Existing reference ───────────────────────────────────────
resource existing 'Microsoft.Web/serverfarms@2023-12-01' existing = if (useExisting) {
  name: name
}

// ─── New resource ─────────────────────────────────────────────
resource plan 'Microsoft.Web/serverfarms@2023-12-01' = if (!useExisting) {
  name: name
  location: location
  kind: 'linux'
  sku: {
    name: skuName
  }
  properties: {
    reserved: true   // required for Linux
  }
}

output id string = useExisting ? existing.id : plan.id
output name string = useExisting ? existing.name : plan.name
