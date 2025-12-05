// ============================================================================
// Main Bicep Parameters - ZavaStorefront Infrastructure
// ============================================================================
// Purpose: Parameter values for dev environment deployment
// Region: westus3
// ============================================================================

using './main.bicep'

// Environment configuration
param environmentName = 'dev'
param location = 'westus3'
param baseName = 'zavastore'

// Tags
param tags = {
  project: 'zavastore'
  environment: 'dev'
  owner: 'workshop'
}

// Service SKUs
param appServicePlanSku = 'B1'
param containerRegistrySku = 'Basic'
param aiServicesSku = 'S0'

// Monitoring
param logAnalyticsRetentionDays = 30

// Container configuration
param containerImage = 'zavastore:latest'
