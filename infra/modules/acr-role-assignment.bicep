// =========================================================================
// ACR Role Assignment Module
// Assigns AcrPull role to the Web App's managed identity
// =========================================================================

@description('Name of the Azure Container Registry')
param acrName string

@description('Principal ID to assign the role to')
param principalId string

@description('Role definition ID (default: AcrPull)')
param roleDefinitionId string = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

// -------------------------------------------------------------------------
// Existing Resource Reference
// -------------------------------------------------------------------------

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

// -------------------------------------------------------------------------
// Resource - Role Assignment
// -------------------------------------------------------------------------

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, principalId, roleDefinitionId)
  scope: acr
  properties: {
    principalId: principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalType: 'ServicePrincipal'
  }
}

// -------------------------------------------------------------------------
// Outputs
// -------------------------------------------------------------------------

@description('The role assignment resource ID')
output roleAssignmentId string = acrPullRoleAssignment.id
