@description('Principal ID to assign the role to')
param principalId string

@description('Role Definition ID (GUID) to assign')
param roleDefinitionId string

@description('Resource ID of the target resource for role assignment')
param targetResourceId string

@description('Principal type (ServicePrincipal, User, or Group)')
@allowed([
  'ServicePrincipal'
  'User'
  'Group'
])
param principalType string = 'ServicePrincipal'

// Reference the existing resource to properly scope the role assignment
resource targetResource 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: last(split(targetResourceId, '/'))
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principalId, roleDefinitionId, targetResourceId)
  scope: targetResource
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: principalType
  }
}

@description('The name of the role assignment')
output roleAssignmentName string = roleAssignment.name

@description('The resource ID of the role assignment')
output roleAssignmentId string = roleAssignment.id
