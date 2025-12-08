@description('Assign a role to a principal at a scope')
param principalId string
param roleDefinitionId string
param scope object

// roleAssignment name must be a GUID
var roleAssignmentName = guid(scope.id, principalId, roleDefinitionId)

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: roleAssignmentName
  scope: scope
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: principalId
  }
}

output assignedName string = roleAssignment.name
