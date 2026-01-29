@description('The location for the Azure Container Registry')
param location string = resourceGroup().location

@description('The name of the Azure Container Registry')
param registryName string

@description('The SKU for the Azure Container Registry')
@allowed(['Basic', 'Standard', 'Premium'])
param sku string = 'Basic'

@description('Tags to apply to the resource')
param tags object = {}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: registryName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
    policies: {
      retentionPolicy: {
        status: 'disabled'
      }
      trustPolicy: {
        status: 'disabled'
      }
    }
  }
}

@description('The resource ID of the container registry')
output registryId string = containerRegistry.id

@description('The name of the container registry')
output registryName string = containerRegistry.name

@description('The login server of the container registry')
output loginServer string = containerRegistry.properties.loginServer
