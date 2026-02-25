@description('User-assigned managed identity name')
param name string

@description('Resource location')
param location string

resource userIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: name
  location: location
}

output id string = userIdentity.id
