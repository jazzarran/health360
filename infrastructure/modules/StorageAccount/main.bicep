// Parameters
@allowed([
  'qa'
  'uat'
  'prod'
])
param environment string
param projectName string
param location string = resourceGroup().location
param tags object = {}

@allowed([
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GRS'
  'Standard_GZRS'
  'Standard_LRS'
  'Standard_RAGRS'
  'Standard_RAGZRS'
  'Standard_ZRS'
])
param sku string = 'Standard_LRS'

@allowed([
  'BlobStorage'
  'BlockBlobStorage'
  'FileStorage'
  'Storage'
  'StorageV2'
])
param kind string = 'StorageV2'

@allowed([
  'Cool'
  'Hot'
])
param accessTier string = 'Hot'

param locationMapping object = {
  'eastus': 'e1'
  'eastus2': 'e2'
  'eastus3': 'e3'
  'westus': 'w1'
  'westus2': 'w2'
  'westus3': 'w3'
}

// Variables
var saName = '${projectName}sa${locationMapping[toLower(location)]}${environment}'

// Resources
resource sa 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: saName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  kind: kind
  identity: {
    type: 'None'
    userAssignedIdentities: {}
  }
  properties: {
    accessTier: accessTier
    allowBlobPublicAccess: true
    allowCrossTenantReplication: true
    allowedCopyScope: 'AAD'
    allowSharedKeyAccess: true
    defaultToOAuthAuthentication: false
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    immutableStorageWithVersioning: {
      enabled: false
    }
    isHnsEnabled: false
    isLocalUserEnabled: false
    isNfsV3Enabled: false
    isSftpEnabled: false
    largeFileSharesState: 'Disabled'
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Enabled'
    supportsHttpsTrafficOnly: true
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' = {
  parent: sa
  name: 'default'
}

// Output
output Id string = sa.id
output Name string = sa.name
