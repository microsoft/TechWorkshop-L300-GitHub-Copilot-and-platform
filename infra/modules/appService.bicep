param appServicePlanName string
param webAppName string
param location string
param sku string = 'B1'
param tier string = 'Basic'

@allowed([
  'DOTNETCORE|8.0'
  'DOTNETCORE|9.0'
  'DOTNETCORE|10.0'
  'NODE|18-lts'
  'PYTHON|3.11'
])
param linuxFxVersion string = 'DOTNETCORE|8.0'

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: appServicePlanName
  location: location
  kind: 'linux'
  sku: {
    name: sku
    tier: tier
  }
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: webAppName
  location: location
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: linuxFxVersion
    }
  }
}
