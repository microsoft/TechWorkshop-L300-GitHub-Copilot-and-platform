// ============================================================================
// Azure AI Services (Cognitive Services) Module
// Provides access to GPT-4 and Phi models via Microsoft Foundry
// ============================================================================

@description('Name of the AI Services account')
param name string

@description('Location for the resource')
param location string = resourceGroup().location

@description('Tags to apply to the resource')
param tags object = {}

@description('SKU for the AI Services account')
@allowed([
  'S0'
  'F0'
])
param skuName string = 'S0'

@description('Kind of cognitive service')
@allowed([
  'AIServices'
  'OpenAI'
  'CognitiveServices'
])
param kind string = 'AIServices'

@description('Whether to deploy GPT-4o model')
param deployGpt4o bool = true

@description('Whether to deploy Phi model')
param deployPhi bool = true

// Deploy AI Services using Azure Verified Module
module aiServices 'br/public:avm/res/cognitive-services/account:0.10.1' = {
  name: 'aiServicesDeployment'
  params: {
    name: name
    location: location
    tags: tags
    kind: kind
    sku: skuName
    
    // Enable managed identity
    managedIdentities: {
      systemAssigned: true
    }
    
    // Model deployments
    deployments: concat(
      deployGpt4o ? [
        {
          name: 'gpt-4o'
          model: {
            format: 'OpenAI'
            name: 'gpt-4o'
            version: '2024-08-06'
          }
          sku: {
            name: 'GlobalStandard'
            capacity: 10
          }
        }
      ] : [],
      deployPhi ? [
        {
          name: 'gpt-4o-mini'
          model: {
            format: 'OpenAI'
            name: 'gpt-4o-mini'
            version: '2024-07-18'
          }
          sku: {
            name: 'GlobalStandard'
            capacity: 10
          }
        }
      ] : []
    )
    
    // Public network access for dev
    publicNetworkAccess: 'Enabled'
    
    // Disable local auth (use managed identity)
    disableLocalAuth: false
  }
}

// Outputs
@description('The resource ID of the AI Services account')
output resourceId string = aiServices.outputs.resourceId

@description('The name of the AI Services account')
output name string = aiServices.outputs.name

@description('The endpoint of the AI Services account')
output endpoint string = aiServices.outputs.endpoint
