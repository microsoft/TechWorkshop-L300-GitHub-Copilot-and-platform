// Azure Container Registry module
// Creates and configures ACR for Docker image storage

@description('Container Registry name')
param acrName string

@description('Azure region for the resource')
param location string

@description('Principal ID of Managed Identity for RBAC assignment')
param managedIdentityPrincipalId string

@description('Environment name')
param environment string

@description('Container Registry SKU')
param sku string = 'Premium'

@description('Enable admin user (not recommended - use RBAC instead)')
param enableAdminUser bool = false

@description('Enable public network access')
param publicNetworkAccess string = 'Enabled'

// Container Registry resource
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  tags: {
    environment: environment
    project: 'ZavaStorefront'
    managedBy: 'AZD'
  }
  sku: {
    name: sku
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    adminUserEnabled: enableAdminUser
    publicNetworkAccess: publicNetworkAccess
    networkRuleBypassOptions: 'AzureServices'
    policies: {
      quarantinePolicy: {
        status: 'disabled'
      }
      trustPolicy: {
        type: 'Notary'
        status: 'disabled'
      }
      retentionPolicy: {
        days: 30
        status: 'enabled'
      }
    }
  }
}

// Assign AcrPull role to Managed Identity
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: containerRegistry
  name: guid(containerRegistry.id, managedIdentityPrincipalId, 'acrpull')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull role
    principalId: managedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
@description('Container Registry URL')
output acrUrl string = containerRegistry.properties.loginServer

@description('Container Registry ID')
output acrId string = containerRegistry.id

@description('Container Registry Name')
output acrName string = containerRegistry.name

@description('Container Registry Resource Group')
output acrResourceGroup string = resourceGroup().name
