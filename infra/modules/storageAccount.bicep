@description('Name of the Storage Account')
param storageAccountName string

@description('Location for the Storage Account')
param location string = resourceGroup().location

@description('SKU for the Storage Account')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
])
param sku string = 'Standard_LRS'

@description('Tags to apply to the resource')
param tags object = {}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

@description('The resource ID of the Storage Account')
output storageAccountId string = storageAccount.id

@description('The name of the Storage Account')
output storageAccountName string = storageAccount.name
