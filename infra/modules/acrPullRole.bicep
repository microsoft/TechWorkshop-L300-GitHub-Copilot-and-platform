@description('Name of the ACR to grant pull access on')
param acrName string

@description('Principal ID of the managed identity (e.g. Web App system identity)')
param principalId string

// AcrPull built-in role: 7f951dda-4ed3-4680-a7ca-43fe172d538d
var acrPullRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

// Role assignments are idempotent — redeploying with the same
// principal + role + scope is a no-op, so this is safe to run repeatedly.
resource acrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, principalId, acrPullRoleId)
  scope: acr
  properties: {
    roleDefinitionId: acrPullRoleId
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
