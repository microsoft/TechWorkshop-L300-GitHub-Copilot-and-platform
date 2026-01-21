// Application Insights module
param resourceGroupName string
param location string
param environment string

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'zavastore-ai-${environment}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

output instrumentationKey string = appInsights.properties.InstrumentationKey
