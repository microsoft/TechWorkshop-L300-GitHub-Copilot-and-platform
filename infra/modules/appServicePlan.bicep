// App Service Plan module
param name string
param location string
param skuName string = 'P1v2'
param isLinux bool = false
resource asp 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: name
  location: location
  sku: {
    name: skuName
  }
  properties: {
    reserved: isLinux
  }
}
output aspId string = asp.id
