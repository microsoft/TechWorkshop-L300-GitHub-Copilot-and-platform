// Key Vault module
param name string
param location string
param tenantId string
param skuName string = 'standard'
resource kv 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: name
  location: location
  properties: {
    tenantId: tenantId
    sku: {
      family: 'A'
      name: skuName
    }
    accessPolicies: []
    enableSoftDelete: true
    enablePurgeProtection: true
  }
}
output keyVaultUri string = kv.properties.vaultUri
