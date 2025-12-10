// Managed Identity module
// Creates a User-Assigned Managed Identity for RBAC and secure resource access

@description('Managed Identity name')
param managedIdentityName string

@description('Azure region for the resource')
param location string

@description('Environment name')
param environment string

// User-Assigned Managed Identity
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
  tags: {
    environment: environment
    project: 'ZavaStorefront'
    managedBy: 'AZD'
  }
}

// Outputs
@description('Managed Identity ID')
output managedIdentityId string = managedIdentity.id

@description('Managed Identity Principal ID (Object ID)')
output managedIdentityPrincipalId string = managedIdentity.properties.principalId

@description('Managed Identity Client ID')
output managedIdentityClientId string = managedIdentity.properties.clientId

@description('Managed Identity Tenant ID')
output managedIdentityTenantId string = managedIdentity.properties.tenantId

@description('Managed Identity Name')
output managedIdentityName string = managedIdentity.name

@description('Managed Identity Object ID')
output managedIdentityObjectId string = managedIdentity.properties.principalId
