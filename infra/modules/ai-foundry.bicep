targetScope = 'resourceGroup'

// ============================================================================
// PARAMETERS
// ============================================================================

@description('Base name for all resources')
param name string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Tags to apply to all resources')
param tags object = {}

@description('The SKU of the AI Services account')
@allowed(['S0'])
param sku string = 'S0'

@description('The principal ID of the App Service for role assignment')
param appServicePrincipalId string

// ============================================================================
// VARIABLES
// ============================================================================

var resourceSuffix = take(uniqueString(subscription().id, resourceGroup().name, name), 6)
var aiServicesName = 'ai-${name}-${resourceSuffix}'

// Cognitive Services User role definition ID
var cognitiveServicesUserRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a97b65f3-24c7-4388-baec-2e87135dc908')

// ============================================================================
// AI SERVICES (Azure AI Foundry - Multi-service account)
// ============================================================================

resource aiServices 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: aiServicesName
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: sku
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: aiServicesName
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
      ipRules: []
      virtualNetworkRules: []
    }
    disableLocalAuth: false
  }
}

// ============================================================================
// MODEL DEPLOYMENTS (GPT-4o and Phi-3.5)
// ============================================================================

resource gpt4oDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: aiServices
  name: 'gpt-4o'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o'
      version: '2024-11-20'
    }
    raiPolicyName: 'Microsoft.Default'
  }
}

resource phi35Deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: aiServices
  name: 'phi-35-mini-instruct'
  sku: {
    name: 'GlobalStandard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'Microsoft'
      name: 'Phi-3.5-mini-instruct'
      version: '2'
    }
    raiPolicyName: 'Microsoft.Default'
  }
  dependsOn: [
    gpt4oDeployment // Sequential deployment to avoid conflicts
  ]
}

// ============================================================================
// ROLE ASSIGNMENT (Cognitive Services User for App Service)
// ============================================================================

resource cognitiveServicesUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiServices.id, appServicePrincipalId, cognitiveServicesUserRoleId)
  scope: aiServices
  properties: {
    principalId: appServicePrincipalId
    roleDefinitionId: cognitiveServicesUserRoleId
    principalType: 'ServicePrincipal'
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

@description('The name of the AI Services account')
output name string = aiServices.name

@description('The endpoint of the AI Services account')
output endpoint string = aiServices.properties.endpoint

@description('The resource ID of the AI Services account')
output resourceId string = aiServices.id

@description('The principal ID of the AI Services managed identity')
output principalId string = aiServices.identity.principalId
