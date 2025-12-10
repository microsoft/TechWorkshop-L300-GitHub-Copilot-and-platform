// Azure Key Vault module
// Creates Key Vault for secure secrets and configuration management

@description('Key Vault name')
param keyVaultName string

@description('Azure region for the resource')
param location string

@description('Tenant ID')
param tenantId string = subscription().tenantId

@description('Managed Identity Object ID for access policy')
param managedIdentityObjectId string

@description('Environment name')
param environment string

@description('Enable soft delete')
param enableSoftDelete bool = true

@description('Soft delete retention days')
param softDeleteRetentionDays int = 90

@description('Enable purge protection')
param enablePurgeProtection bool = true

@description('Enable RBAC authorization')
param enableRbacAuthorization bool = true

// Key Vault resource
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: {
    environment: environment
    project: 'ZavaStorefront'
    managedBy: 'AZD'
  }
  properties: {
    tenantId: tenantId
    sku: {
      family: 'A'
      name: 'premium'
    }
    accessPolicies: enableRbacAuthorization ? [] : [
      {
        tenantId: tenantId
        objectId: managedIdentityObjectId
        permissions: {
          keys: [
            'get'
            'list'
          ]
          secrets: [
            'get'
            'list'
          ]
          certificates: [
            'get'
            'list'
          ]
        }
      }
    ]
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: softDeleteRetentionDays
    enablePurgeProtection: enablePurgeProtection
    enableRbacAuthorization: enableRbacAuthorization
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Role Assignment for Managed Identity (if RBAC enabled)
resource keyVaultSecretsUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableRbacAuthorization) {
  scope: keyVault
  name: guid(keyVault.id, managedIdentityObjectId, 'keyVaultSecretsUser')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User
    principalId: managedIdentityObjectId
    principalType: 'ServicePrincipal'
  }
}

// Example Secret (placeholder - update with actual values)
resource exampleSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'AppSettings'
  properties: {
    value: 'placeholder-value'
  }
}

// Outputs
@description('Key Vault ID')
output keyVaultId string = keyVault.id

@description('Key Vault URI')
output keyVaultUri string = keyVault.properties.vaultUri

@description('Key Vault Name')
output keyVaultName string = keyVault.name

@description('Key Vault Resource Group')
output keyVaultResourceGroup string = resourceGroup().name
