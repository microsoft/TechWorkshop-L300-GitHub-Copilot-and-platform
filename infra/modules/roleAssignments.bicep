// RBAC Role Assignments for managed identity access
@description('The principal ID of the managed identity to grant access')
param principalId string

@description('The resource ID of the Azure Container Registry')
param acrId string

@description('The resource ID of the Azure OpenAI account')
param openAiId string

@description('The principal type (default: ServicePrincipal for managed identity)')
param principalType string = 'ServicePrincipal'

// AcrPull role definition ID (built-in role)
var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

// Cognitive Services OpenAI User role definition ID (built-in role)
var cognitiveServicesOpenAIUserRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd')

// Reference existing ACR
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: last(split(acrId, '/'))
}

// Reference existing OpenAI account
resource openai 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: last(split(openAiId, '/'))
}

// Role assignment for ACR Pull
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acrId, principalId, acrPullRoleDefinitionId)
  scope: acr
  properties: {
    roleDefinitionId: acrPullRoleDefinitionId
    principalId: principalId
    principalType: principalType
  }
}

// Role assignment for Azure OpenAI User
resource openAiUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(openAiId, principalId, cognitiveServicesOpenAIUserRoleDefinitionId)
  scope: openai
  properties: {
    roleDefinitionId: cognitiveServicesOpenAIUserRoleDefinitionId
    principalId: principalId
    principalType: principalType
  }
}

@description('The role assignment ID for ACR Pull')
output acrPullRoleAssignmentId string = acrPullRoleAssignment.id

@description('The role assignment ID for OpenAI User')
output openAiUserRoleAssignmentId string = openAiUserRoleAssignment.id
