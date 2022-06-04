// *** Parameters *** //
@allowed([
  'qa'
  'uat'
  'prod'
])
param environment string
param projectName string
param location string = resourceGroup().location
param tags object = {}

param locationMapping object = {
  'eastus': 'e1'
  'eastus2': 'e2'
  'eastus3': 'e3'
  'westus': 'w1'
  'westus2': 'w2'
  'westus3': 'w3'
}

param dbSubnetId string

var serverDeploymentName = '${projectName}-postgresdb-${locationMapping[toLower(location)]}-${environment}'

@minLength(4)
param administratorLogin string
@minLength(8)
@secure()
param administratorLoginPassword string

@allowed([
  'Basic'
  'GeneralPurpose'
  'MemoryOptimized'
])
param skuTier string = 'GeneralPurpose'
param skuCapacity int = 2
param skuName string = 'GP_Gen5_2'
param skuSizeMB int = 51200
param skuFamily string = 'Gen5'

@allowed([
  '9.5'
  '9.6'
  '10'
  '10.0'
  '10.2'
  '11'
])
param postgresqlVersion string = '11'

param backupRetentionDays int = 7
param geoRedundantBackup string = 'Disabled'
param virtualNetworkRuleName string = 'AllowSubnet'

// *** Variables *** //
var firewallrules = [
  {
    Name: 'rule1'
    StartIpAddress: '0.0.0.0'
    EndIpAddress: '255.255.255.255'
  }
  {
    Name: 'rule2'
    StartIpAddress: '0.0.0.0'
    EndIpAddress: '255.255.255.255'
  }
]

// *** Resources *** //

// Resource (Imports)
resource primaryVNET 'Microsoft.Network/virtualNetworks@2019-11-01' existing = {
  name: 'primaryVirtualNetwork'
}

// Resources
resource server 'Microsoft.DBforPostgreSQL/servers@2017-12-01' = {
  name: serverDeploymentName
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: skuTier
    capacity: skuCapacity
    size: '${skuSizeMB}'
    family: skuFamily
  }
  properties: {
    createMode: 'Default'
    version: postgresqlVersion
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    storageProfile: {
      storageMB: skuSizeMB
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup
    }
  }

  resource virtualNetworkRule 'virtualNetworkRules@2017-12-01' = {
    name: virtualNetworkRuleName
    properties: {
      virtualNetworkSubnetId: dbSubnetId
      ignoreMissingVnetServiceEndpoint: true
    }
  }
}

@batchSize(1)
resource firewallRules 'Microsoft.DBforPostgreSQL/servers/firewallRules@2017-12-01' = [for rule in firewallrules: {
  name: '${server.name}/${rule.Name}'
  properties: {
    startIpAddress: rule.StartIpAddress
    endIpAddress: rule.EndIpAddress
  }
}]
