// Application Insights module
param location string
param environment string

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'zavastoreai${environment}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

output instrumentationKey string = appInsights.properties.InstrumentationKey
output connectionString string = appInsights.properties.ConnectionString
