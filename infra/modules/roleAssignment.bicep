// Role Assignment module
// Assigns AcrPull role to the Web App's managed identity for secure ACR access

@description('Principal ID to assign the role to')
param principalId string

@description('Role definition ID (e.g., AcrPull = 7f951dda-4ed3-4680-a7ca-43fe172d538d)')
param roleDefinitionId string

@description('Principal type')
@allowed([
  'ServicePrincipal'
  'User'
  'Group'
])
param principalType string = 'ServicePrincipal'

@description('Name of the Container Registry')
param containerRegistryName string

// Reference to existing ACR
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: containerRegistryName
}

// Role Assignment
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistry.id, principalId, roleDefinitionId)
  scope: containerRegistry
  properties: {
    principalId: principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalType: principalType
  }
}

@description('The resource ID of the role assignment')
output id string = roleAssignment.id
