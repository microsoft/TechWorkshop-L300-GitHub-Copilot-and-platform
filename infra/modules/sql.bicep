// SQL Server & Database module
param serverName string
param dbName string
param location string
param adminLogin string
@secure()
param adminPassword string
param skuName string = 'S0'
resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: serverName
  location: location
  properties: {
    administratorLogin: adminLogin
    administratorLoginPassword: adminPassword
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
  }
}
resource sqlDb 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  name: '${serverName}/${dbName}'
  location: location
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 2147483648
  }
  sku: {
    name: skuName
  }
  dependsOn: [sqlServer]
}
// Output removed: do not output secrets
