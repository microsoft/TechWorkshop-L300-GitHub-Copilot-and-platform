// ============================================================================
// Azure AI Services Module
// ============================================================================
// Purpose: Deploy Azure AI Services (Cognitive Services) for AI capabilities
// Models: GPT-4, Phi (verify availability in target region)
// Security: Managed identity support, disable local auth for production
// ============================================================================

@description('The name of the Azure AI Services resource')
param name string

@description('Location for the resource')
param location string = resourceGroup().location

@description('Kind of AI service')
@allowed(['AIServices', 'OpenAI', 'CognitiveServices'])
param kind string = 'AIServices'

@description('SKU name for the AI service')
@allowed(['S0', 'F0'])
param skuName string = 'S0'

@description('Custom subdomain name for the AI service (must be globally unique)')
param customSubDomainName string

@description('Model deployments to create')
param deployments array = []

@description('Tags for the resource')
param tags object = {}

// ============================================================================
// Resources
// ============================================================================

resource aiServices 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: name
  location: location
  tags: tags
  kind: kind
  sku: {
    name: skuName
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: customSubDomainName
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false // Set to true for production
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

// Deploy models if specified
resource modelDeployments 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = [
  for deployment in deployments: {
    parent: aiServices
    name: deployment.name
    sku: {
      name: deployment.?sku.?name ?? 'Standard'
      capacity: deployment.?sku.?capacity ?? 10
    }
    properties: {
      model: {
        format: deployment.model.format
        name: deployment.model.name
        version: deployment.model.version
      }
      versionUpgradeOption: deployment.?versionUpgradeOption ?? 'OnceNewDefaultVersionAvailable'
    }
  }
]

// ============================================================================
// Outputs
// ============================================================================

@description('The resource ID of the AI Services resource')
output resourceId string = aiServices.id

@description('The name of the AI Services resource')
output name string = aiServices.name

@description('The endpoint of the AI Services resource')
output endpoint string = aiServices.properties.endpoint

@description('The principal ID of the system-assigned managed identity')
output principalId string = aiServices.identity.principalId
