param resourceName string
param location string
param appServicePlanId string
param userAssignedIdentityResourceId string
param userAssignedIdentityClientId string
param appInsightsConnectionString string
param containerImage string
param serviceName string

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: resourceName
  location: location
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityResourceId}': {}
    }
  }
  tags: {
    'azd-service-name': serviceName
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerImage}'
      acrUseManagedIdentityCreds: true
      acrUserManagedIdentityID: userAssignedIdentityClientId
      appSettings: [
        {
          name: 'WEBSITES_PORT'
          value: '8080'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
      ]
      http20Enabled: true
      minTlsVersion: '1.2'
      ftpsState: 'FtpsOnly'
    }
  }
}

resource appInsightsExtension 'Microsoft.Web/sites/siteextensions@2023-12-01' = {
  name: 'ApplicationInsightsAgent'
  parent: webApp
}

output id string = webApp.id
output principalId string = webApp.identity.principalId
