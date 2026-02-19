
param location string = 'westus3'
param acrName string = 'zavastoreacr'
param logAnalyticsName string = 'zavastore-logs'
param appServicePlanName string = 'zavastore-asp'
param webAppName string = 'zavastore-webapp'
param linuxFxVersion string = 'DOTNETCORE|8.0'

module acr 'modules/acr.bicep' = {
  name: 'acrModule'
  params: {
    acrName: acrName
    location: location
    sku: 'Basic'
  }
}
module logAnalytics 'modules/logAnalytics.bicep' = {
  name: 'logAnalyticsModule'
  params: {
    logAnalyticsName: logAnalyticsName
    location: location
    skuName: 'PerGB2018'
  }
}
module appService 'modules/appService.bicep' = {
  name: 'appServiceModule'
  params: {
    appServicePlanName: appServicePlanName
    webAppName: webAppName
    location: location
    sku: 'B1'
    tier: 'Basic'
    linuxFxVersion: linuxFxVersion
  }
}
// ...other modules as needed
