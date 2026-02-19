param resourceName string
param location string

resource registry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: resourceName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
  }
}

output id string = registry.id
output loginServer string = registry.properties.loginServer
