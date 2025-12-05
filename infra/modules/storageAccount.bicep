@description('Name of the Storage Account')
param storageAccountName string

@description('Location for the Storage Account')
param location string = resourceGroup().location

@description('Tags to apply to the Storage Account')
param tags object = {}

@description('SKU for the Storage Account')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
])
param sku string = 'Standard_LRS'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
  }
}

@description('The name of the Storage Account')
output storageAccountName string = storageAccount.name

@description('The resource ID of the Storage Account')
output storageAccountId string = storageAccount.id

@description('The primary endpoints of the Storage Account')
output primaryEndpoints object = storageAccount.properties.primaryEndpoints
