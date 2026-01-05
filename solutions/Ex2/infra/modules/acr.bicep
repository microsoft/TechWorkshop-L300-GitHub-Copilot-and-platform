// Azure Container Registry Module
@description('Name of the Azure Container Registry')
param acrName string

@description('Location for the ACR')
param location string = resourceGroup().location

@description('ACR SKU')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string = 'Basic'

@description('Enable admin user (not recommended for production)')
param adminUserEnabled bool = false

@description('Tags for the resource')
param tags object = {}

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: sku
  }
  tags: tags
  properties: {
    adminUserEnabled: adminUserEnabled
    publicNetworkAccess: 'Enabled'
  }
}

@description('The login server for the ACR')
output loginServer string = acr.properties.loginServer

@description('The resource ID of the ACR')
output acrId string = acr.id

@description('The name of the ACR')
output acrName string = acr.name
