@description('Name of the Azure AI Foundry (Azure OpenAI) account')
param accountName string

@description('Azure region for the account')
param location string

@description('SKU name for Azure OpenAI account')
param skuName string

resource foundry 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: accountName
  location: location
  kind: 'OpenAI'
  sku: {
    name: skuName
  }
  properties: {
    customSubDomainName: accountName
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: true
  }
}

output accountName string = foundry.name
output endpoint string = foundry.properties.endpoint
output accountResourceId string = foundry.id
