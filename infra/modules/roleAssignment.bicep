// Role Assignment Module
// Assigns AcrPull role to the Web App managed identity on ACR

@description('Resource ID of the ACR')
param acrId string

@description('Principal ID of the Web App system-assigned managed identity')
param webAppPrincipalId string

// AcrPull built-in role definition ID
var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acrId, webAppPrincipalId, acrPullRoleDefinitionId)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: acrPullRoleDefinitionId
    principalId: webAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output roleAssignmentId string = acrPullRoleAssignment.id
