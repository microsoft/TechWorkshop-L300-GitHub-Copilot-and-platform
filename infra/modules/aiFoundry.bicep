@description('The name of the AI Foundry Hub')
param hubName string

@description('The name of the AI Foundry Project')
param projectName string

@description('The location for AI Foundry resources')
param location string = resourceGroup().location

@description('The resource ID of the Application Insights instance')
param applicationInsightsId string

@description('The resource ID of the Container Registry')
param containerRegistryId string

@description('The resource ID of the Log Analytics Workspace')
param workspaceId string

@description('Tags to apply to AI Foundry resources')
param tags object = {}

// Generate shorter unique names for storage and key vault (24 char limit)
var storageAccountName = take(replace('st${uniqueString(resourceGroup().id, hubName)}', '-', ''), 24)
var keyVaultName = take('kv${uniqueString(resourceGroup().id, hubName)}', 24)

// Storage account for AI Foundry
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

// Key Vault for AI Foundry
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: []
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
  }
}

// AI Foundry Hub (Azure Machine Learning Workspace)
resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: hubName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: hubName
    description: 'AI Foundry Hub for ZavaStorefront'
    storageAccount: storageAccount.id
    keyVault: keyVault.id
    applicationInsights: applicationInsightsId
    containerRegistry: containerRegistryId
    publicNetworkAccess: 'Enabled'
    v1LegacyMode: false
  }
  kind: 'Hub'
}

// AI Foundry Project
resource aiProject 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: projectName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: projectName
    description: 'AI Foundry Project for ZavaStorefront development'
    hubResourceId: aiHub.id
    publicNetworkAccess: 'Enabled'
  }
  kind: 'Project'
}

@description('The resource ID of the AI Foundry Hub')
output hubResourceId string = aiHub.id

@description('The name of the AI Foundry Hub')
output hubName string = aiHub.name

@description('The resource ID of the AI Foundry Project')
output projectResourceId string = aiProject.id

@description('The name of the AI Foundry Project')
output projectName string = aiProject.name

@description('The principal ID of the AI Hub managed identity')
output hubPrincipalId string = aiHub.identity.principalId

@description('The principal ID of the AI Project managed identity')
output projectPrincipalId string = aiProject.identity.principalId

@description('The location of the AI Foundry resources')
output location string = location
