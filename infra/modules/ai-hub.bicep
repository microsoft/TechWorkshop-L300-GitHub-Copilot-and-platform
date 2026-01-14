// Azure AI Hub (Microsoft Foundry) module
@description('Name of the AI Hub')
param name string

@description('Location for the AI Hub')
param location string

@description('Tags to apply to the resource')
param tags object = {}

@description('Application Insights resource ID')
param appInsightsId string

@description('Friendly name for the AI Hub')
param friendlyName string = 'Zava Storefront AI Hub'

@description('Description of the AI Hub')
param hubDescription string = 'AI Hub for GPT-4 and Phi model access'

// Generate short unique suffix
var uniqueSuffix = substring(uniqueString(resourceGroup().id), 0, 6)

// Storage Account for AI Hub
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'staih${uniqueSuffix}'
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
  }
}

// Key Vault for AI Hub
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-aih-${uniqueSuffix}'
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enableRbacAuthorization: true
  }
}

// AI Hub Resource
resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: name
  location: location
  tags: tags
  kind: 'Hub'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: friendlyName
    description: hubDescription
    storageAccount: storageAccount.id
    keyVault: keyVault.id
    applicationInsights: appInsightsId
    publicNetworkAccess: 'Enabled'
  }
}

output id string = aiHub.id
output name string = aiHub.name
output principalId string = aiHub.identity.principalId
