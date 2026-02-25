targetScope = 'resourceGroup'

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

@description('Name of the ACR resource to grant the AcrPull role on.')
param acrName string

@description('Principal ID (object ID) of the Web App system-assigned managed identity.')
param webAppPrincipalId string

// ---------------------------------------------------------------------------
// Variables
// ---------------------------------------------------------------------------

// AcrPull built-in role: 7f951dda-4ed3-4680-a7ca-43fe172d538d
var acrPullRoleDefinitionId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '7f951dda-4ed3-4680-a7ca-43fe172d538d'
)

// ---------------------------------------------------------------------------
// Existing resource reference
// ---------------------------------------------------------------------------

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

// ---------------------------------------------------------------------------
// Role Assignment: Web App managed identity → AcrPull on ACR
// ---------------------------------------------------------------------------

resource acrPullAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  // Deterministic GUID based on scope + principal + role
  name: guid(acr.id, webAppPrincipalId, acrPullRoleDefinitionId)
  scope: acr
  properties: {
    roleDefinitionId: acrPullRoleDefinitionId
    principalId: webAppPrincipalId
    principalType: 'ServicePrincipal'
    description: 'Allow Web App managed identity to pull images from ACR (no password)'
  }
}
