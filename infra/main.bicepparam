// =============================================================================
// ZavaStorefront Infrastructure - Parameter File for Development Environment
// =============================================================================

using 'main.bicep'

// Application name - used as prefix for all resources
param appName = 'zavastore'

// Environment type
param environment = 'dev'

// Azure region - using westus3 for Microsoft Foundry model availability
param location = 'westus3'

// App Service Plan SKU - B1 is cost-effective for development
param appServicePlanSku = 'B1'

// Azure Container Registry SKU - Basic is cost-effective for dev
param acrSku = 'Basic'

// Resource tags
param tags = {
  Application: 'ZavaStorefront'
  Environment: 'dev'
  ManagedBy: 'Bicep'
  Project: 'TechWorkshop-L300'
}
