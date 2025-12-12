// Web App (Linux) module
param serviceName string = 'storefront'
param location string
param appServicePlanId string
param appInsightsConnectionString string = ''
param foundryEndpoint string = ''
param foundryApiKey string = ''
@description('Port the container listens on (ASP.NET 8 container default: 8080)')
param containerPort string = '8080'

var webAppName = 'zavastoreweblinux${uniqueString(resourceGroup().id, 'linux')}'
var baseAppSettings = [
  {
    name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
    value: 'false'
  }
  {
    name: 'WEBSITES_PORT'
    value: containerPort
  }
  {
    name: 'ASPNETCORE_URLS'
    value: 'http://+:${containerPort}'
  }
]
var optionalAppSettings = concat(
  empty(appInsightsConnectionString) ? [] : [
    {
      name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
      value: appInsightsConnectionString
    }
  ],
  empty(foundryEndpoint) ? [] : [
    {
      name: 'AZURE_FOUNDRY_ENDPOINT'
      value: foundryEndpoint
    }
  ],
  empty(foundryApiKey) ? [] : [
    {
      name: 'AZURE_FOUNDRY_API_KEY'
      value: foundryApiKey
    }
  ]
)

resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  location: location
  kind: 'app,linux,container'
  tags: {
    'azd-service-name': serviceName
  }
  properties: {
    reserved: true
    serverFarmId: appServicePlanId
    siteConfig: {
      acrUseManagedIdentityCreds: true
      appSettings: concat(baseAppSettings, optionalAppSettings)
    }
    httpsOnly: true
  }
  identity: {
    type: 'SystemAssigned'
  }
}

output principalId string = webApp.identity.principalId
output webAppName string = webApp.name
output webAppHostname string = webApp.properties.defaultHostName
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
