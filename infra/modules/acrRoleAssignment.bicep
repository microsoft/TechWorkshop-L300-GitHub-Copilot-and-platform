// =========================================================================
// ACR Role Assignment Module
// =========================================================================
// This module assigns a role to a principal on an Azure Container Registry
// =========================================================================

@description('The name of the container registry')
param containerRegistryName string

@description('The principal ID to assign the role to')
param principalId string

@description('The type of principal')
@allowed([
  'Device'
  'ForeignGroup'
  'Group'
  'ServicePrincipal'
  'User'
])
param principalType string

@description('The role definition ID to assign (e.g., AcrPull = 7f951dda-4ed3-4680-a7ca-43fe172d538d)')
param roleDefinitionId string

// Reference to existing container registry
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-06-01-preview' existing = {
  name: containerRegistryName
}

// Role assignment
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistry.id, principalId, roleDefinitionId)
  scope: containerRegistry
  properties: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
  }
}

output roleAssignmentId string = roleAssignment.id
