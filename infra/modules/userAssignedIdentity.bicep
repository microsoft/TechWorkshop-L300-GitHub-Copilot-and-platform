param location string
param identityName string

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}

output id string = userAssignedIdentity.id
output principalId string = userAssignedIdentity.properties.principalId
