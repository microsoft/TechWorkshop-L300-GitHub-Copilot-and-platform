// Web App for Containers module
param resourceGroupName string
param location string
param environment string
param appServicePlanId string
param acrLoginServer string
param appInsightsInstrumentationKey string

resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: 'zavastore-${environment}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  tags: {
    'azd-service-name': 'web'
  }
  properties: {
    serverFarmId: appServicePlanId
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acrLoginServer}/zavastorefront:latest'
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: ''
        }
      ]
      acrUseManagedIdentityCreds: true
      acrUserManagedIdentityID: ''
    }
  }
}

output principalId string = webApp.identity.principalId
output webAppName string = webApp.name
