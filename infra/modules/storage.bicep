// Storage Account module
param name string
param location string
param skuName string = 'Standard_LRS'
param enableHttpsTrafficOnly bool = true
param allowBlobPublicAccess bool = false
resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: name
  location: location
  kind: 'StorageV2'
  sku: {
    name: skuName
  }
  properties: {
    allowBlobPublicAccess: allowBlobPublicAccess
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: enableHttpsTrafficOnly
  }
}
// Output removed: do not output secrets
