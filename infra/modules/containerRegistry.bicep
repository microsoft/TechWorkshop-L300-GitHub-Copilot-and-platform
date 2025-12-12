@description('Location for the Container Registry')
param location string

@description('Name of the Container Registry')
param registryName string

@description('Environment name for tagging')
param environmentName string

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-06-01-preview' = {
  name: registryName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
  }
  tags: {
    'azd-env-name': environmentName
  }
}

@description('The login server URL of the Container Registry')
output loginServer string = containerRegistry.properties.loginServer

@description('The resource ID of the Container Registry')
output id string = containerRegistry.id

@description('The name of the Container Registry')
output name string = containerRegistry.name
