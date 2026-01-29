using './main.bicep'

param environmentName = 'dev'
param location = 'westus3'
param appName = 'zavastore'
param acrSku = 'Basic'
param appServicePlanSku = 'B1'
param containerImageName = 'zavastore:latest'
param foundrySku = 'S0'
// Skip model deployments initially - add them later through Azure Portal with correct model names
param foundryModelDeployments = []
