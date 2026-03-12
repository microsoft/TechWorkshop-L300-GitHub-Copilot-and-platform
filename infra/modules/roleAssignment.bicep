@description('Resource ID of the Azure Container Registry to scope the role assignment to.')
param acrId string

@description('Principal ID of the Web App system-assigned managed identity.')
param webAppPrincipalId string

// AcrPull built-in role definition ID
// https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#acrpull
var acrPullRoleDefinitionId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '7f951dda-4ed3-4680-a7ca-43fe172d538d'
)

resource acrPullAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  // Deterministic GUID scoped to this ACR + principal to avoid duplicate assignments
  name: guid(acrId, webAppPrincipalId, acrPullRoleDefinitionId)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: acrPullRoleDefinitionId
    principalId: webAppPrincipalId
    principalType: 'ServicePrincipal'
    description: 'Allow Web App managed identity to pull images from ACR without passwords'
  }
}

@description('Resource ID of the role assignment.')
output id string = acrPullAssignment.id
