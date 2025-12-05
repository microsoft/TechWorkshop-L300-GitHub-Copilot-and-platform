// Role Assignment Module
// For assigning Azure RBAC roles to principals

@description('The principal ID to assign the role to')
param principalId string

@description('The role definition ID (GUID only, not full resource ID)')
param roleDefinitionId string

@description('The principal type')
@allowed([
  'ServicePrincipal'
  'User'
  'Group'
  'Device'
  'ForeignGroup'
])
param principalType string = 'ServicePrincipal'

@description('The target resource ID to scope the role assignment to')
param targetResourceId string

// Generate a unique name for the role assignment
var roleAssignmentName = guid(targetResourceId, roleDefinitionId, principalId)

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: roleAssignmentName
  scope: containerRegistry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: principalType
  }
}

// Reference the existing resource to scope the role assignment
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: last(split(targetResourceId, '/'))
}

@description('The resource ID of the role assignment')
output id string = roleAssignment.id

@description('The name of the role assignment')
output name string = roleAssignment.name
