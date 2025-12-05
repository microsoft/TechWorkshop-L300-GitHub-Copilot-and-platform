// ============================================================================
// Application Insights Module
// Provides application performance monitoring and diagnostics
// ============================================================================

@description('Name of the Application Insights resource')
param name string

@description('Location for the resource')
param location string = resourceGroup().location

@description('Tags to apply to the resource')
param tags object = {}

@description('Resource ID of the Log Analytics workspace')
param workspaceResourceId string

@description('The kind of application type')
@allowed([
  'web'
  'other'
])
param kind string = 'web'

// Deploy Application Insights using Azure Verified Module
module appInsights 'br/public:avm/res/insights/component:0.6.0' = {
  name: 'appInsightsDeployment'
  params: {
    name: name
    location: location
    tags: tags
    workspaceResourceId: workspaceResourceId
    kind: kind
    applicationType: kind
  }
}

// Outputs
@description('The resource ID of the Application Insights')
output resourceId string = appInsights.outputs.resourceId

@description('The name of the Application Insights')
output name string = appInsights.outputs.name

@description('The instrumentation key of the Application Insights')
output instrumentationKey string = appInsights.outputs.instrumentationKey

@description('The connection string of the Application Insights')
output connectionString string = appInsights.outputs.connectionString
