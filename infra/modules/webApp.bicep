param webAppName string
param location string
param appServicePlanId string

resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: webAppName
  location: location
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
    serverFarmId: appServicePlanId
    siteConfig: {
        // Container image not set at provisioning. Add later via update.
    }
  }
}

output principalId string = webApp.identity.principalId
