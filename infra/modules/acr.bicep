// ACR Module
// Provisions Azure Container Registry for ZavaStorefront container images

@description('Name of the Azure Container Registry')
param acrName string

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('SKU for the Container Registry (Basic for dev)')
@allowed(['Basic', 'Standard', 'Premium'])
param acrSku string = 'Basic'

@description('Tags to apply to resources')
param tags object = {}

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: false // Use RBAC, not admin passwords
    publicNetworkAccess: 'Enabled'
  }
}

output acrId string = acr.id
output acrName string = acr.name
output acrLoginServer string = acr.properties.loginServer
