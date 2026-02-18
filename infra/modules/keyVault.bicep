@description('The name of the Key Vault')
@minLength(3)
@maxLength(24)
param name string

@description('The location for the Key Vault')
param location string

@description('Tags to apply to the resource')
param tags object = {}

@description('The Azure Active Directory tenant ID for the Key Vault')
param tenantId string = subscription().tenantId

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    tenantId: tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
  }
}

output id string = keyVault.id
output name string = keyVault.name
output vaultUri string = keyVault.properties.vaultUri
