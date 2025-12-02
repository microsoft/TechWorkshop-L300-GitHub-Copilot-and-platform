// Virtual Network module
// Each subnet must be passed as:
// {
//   name: 'subnetName',
//   properties: {
//     addressPrefix: 'CIDR'
//   }
// }
param name string
param location string
param addressPrefixes array
param subnets array
resource vnet 'Microsoft.Network/virtualNetworks@2023-02-01' = {
  name: name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    subnets: subnets
  }
}
// Output removed: cannot use properties in for-expression at compile time
