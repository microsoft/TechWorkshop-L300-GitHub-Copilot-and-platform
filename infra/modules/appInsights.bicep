// Application Insights Bicep Module
param location string
param environment string

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-zavastorefront-${environment}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

output appInsightsName string = appInsights.name
output appInsightsKey string = appInsights.properties.InstrumentationKey
