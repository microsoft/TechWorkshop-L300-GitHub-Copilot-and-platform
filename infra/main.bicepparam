using './main.bicep'

param environmentName = 'dev'
param location = 'westus3'
param principalId = ''
param tags = {
  'azd-env-name': 'dev'
  project: 'zavastore'
  environment: 'development'
}
