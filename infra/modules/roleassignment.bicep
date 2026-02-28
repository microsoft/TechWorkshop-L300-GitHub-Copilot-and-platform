@description('The principal ID to assign the role to')
param principalId string

@description('The resource ID of the ACR to assign the role on')
param acrId string

@description('The resource ID of the AI Services account. When provided, grants Cognitive Services OpenAI User role.')
param aiServicesId string = ''

// AcrPull built-in role definition ID
var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

// Cognitive Services OpenAI User — allows calling model deployments via Azure AD (no API key)
var cognitiveServicesOpenAIUserRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd')

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acrId, principalId, acrPullRoleDefinitionId)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: acrPullRoleDefinitionId
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

resource aiServicesRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(aiServicesId)) {
  name: guid(aiServicesId, principalId, cognitiveServicesOpenAIUserRoleId)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: cognitiveServicesOpenAIUserRoleId
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
