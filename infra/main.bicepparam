// =========================================================================
// Bicep Parameters File - ZavaStorefront Dev Environment
// =========================================================================
using 'main.bicep'

param environmentName = 'dev'
param location = 'westus3'
param baseName = 'zavastore'
param tags = {
  environment: 'dev'
  project: 'ZavaStorefront'
  deployedWith: 'azd'
}
