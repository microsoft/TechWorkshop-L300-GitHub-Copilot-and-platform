// ============================================================================
// Role Assignment Module
// ============================================================================
// Purpose: Assign Azure RBAC roles to principals
// Usage: Commonly used for AcrPull role assignment from Web App to ACR
// ============================================================================

@description('The principal ID to assign the role to')
param principalId string

@description('The principal type')
@allowed(['User', 'Group', 'ServicePrincipal', 'ForeignGroup', 'Device'])
param principalType string = 'ServicePrincipal'

@description('The role definition ID or built-in role name')
param roleDefinitionId string

@description('The scope for the role assignment (resource ID)')
param scope string

// Built-in role definition IDs
// AcrPull: 7f951dda-4ed3-4680-a7ca-43fe172d538d
// AcrPush: 8311e382-0749-4cb8-b61a-304f252e45ec
// Contributor: b24988ac-6180-42a0-ab88-20f7382dd24c

// ============================================================================
// Resources
// ============================================================================

// Use existing resource to scope the role assignment
resource scopeResource 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: last(split(scope, '/'))
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(scope, principalId, roleDefinitionId)
  scope: scopeResource
  properties: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
  }
}

// ============================================================================
// Outputs
// ============================================================================

@description('The resource ID of the role assignment')
output resourceId string = roleAssignment.id

@description('The name of the role assignment')
output name string = roleAssignment.name
