@description('Azure Container Registry name')
param name string

@description('Resource location')
param location string

@description('If true, reference an existing ACR instead of creating one')
param useExisting bool = false

@description('ACR SKU')
param sku string = 'Basic'

// ─── Existing reference ───────────────────────────────────────
resource existing 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = if (useExisting) {
  name: name
}

// ─── New resource ─────────────────────────────────────────────
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = if (!useExisting) {
  name: name
  location: location
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: false        // RBAC-only, no passwords
  }
}

output id string = useExisting ? existing.id : acr.id
output name string = useExisting ? existing.name : acr.name
output loginServer string = useExisting ? existing.properties.loginServer : acr.properties.loginServer
