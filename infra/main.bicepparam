// ============================================================================
// Parameters File - ZavaStorefront Infrastructure
// Configure environment-specific values here
// ============================================================================

using 'main.bicep'

// Environment Configuration
param environmentName = 'dev'
param location = 'westus3'
param baseName = 'zavastore'

// Tags
param tags = {
  project: 'ZavaStorefront'
  owner: 'DevTeam'
  costCenter: 'Development'
}

// App Service Plan Configuration
// B1 is the minimum for Linux containers and cost-effective for dev
param appServicePlanSku = 'B1'

// Azure Container Registry Configuration
// Basic SKU is sufficient for dev environment
param acrSku = 'Basic'

// AI Services Configuration
param deployAiServices = true
param deployGpt4o = true
param deployPhi = true
