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

param dnsNameForAppsPublicIP string

param locationMapping object = {
  'eastus': 'e1'
  'eastus2': 'e2'
  'eastus3': 'e3'
  'westus': 'w1'
  'westus2': 'w2'
  'westus3': 'w3'
}

// *** Variables *** //
var vNETName = '${projectName}-vnet-${locationMapping[toLower(location)]}-${environment}'
var vNETAddressPrefix = '10.0.0.0/16'

var appsSubnetDeploymentName = '${projectName}-apps-subnet-${locationMapping[toLower(location)]}-${environment}'
var appsNSGDeploymentName = '${projectName}-apps-nsg-${locationMapping[toLower(location)]}-${environment}'
var appsSubnetPrefix = '10.0.0.0/24'

var appsNicDeploymentName = '${projectName}-apps-nic-${locationMapping[toLower(location)]}-${environment}'
var appsPublicIPAddressDeploymentName = '${projectName}-publicip-${locationMapping[toLower(location)]}-${environment}'
var appsPublicIPAddressType = 'Dynamic'

var dbSubnetDeploymentName = '${projectName}-db-subnet-${locationMapping[toLower(location)]}-${environment}'
var dbNSGDeploymentName = '${projectName}-db-nsg-${locationMapping[toLower(location)]}-${environment}'
var dbSubnetPrefix = '10.0.1.0/24'

// *** Resources *** //

// Virtual Network 
resource primaryVirtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: vNETName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNETAddressPrefix
      ]
    }
    subnets: [
      {
        name: appsSubnetDeploymentName
        properties: {
          addressPrefix: appsSubnetPrefix
          networkSecurityGroup: {
            id: appsNSG.id
          }
        }
      }
      {
        name: dbSubnetDeploymentName
        properties: {
          addressPrefix: dbSubnetPrefix
          networkSecurityGroup: {
            id: dbNSG.id
          }
        }
      }
    ]
  }
}

// App Tier
resource appsNSG 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: appsNSGDeploymentName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'default-allow-22'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '22'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'default-allow-8000'
        properties: {
          priority: 1100
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '8000'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource appsPublicIP 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: appsPublicIPAddressDeploymentName
  location: location
  tags: tags
  properties: {
    publicIPAllocationMethod: appsPublicIPAddressType
    dnsSettings: {
      domainNameLabel: dnsNameForAppsPublicIP
    }
  }
}

resource appsNIC 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: appsNicDeploymentName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: appsPublicIP.id
          }
          subnet: {
            id: '${primaryVirtualNetwork.id}/subnets/${appsSubnetDeploymentName}'
          }
        }
      }
    ]
  }
}

// DB Tier
resource dbNSG 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: dbNSGDeploymentName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'default-allow-22'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '22'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

output appsNicResourceId string = appsNIC.id
output dbSubnetResourceId string = '${primaryVirtualNetwork.id}/subnets/${dbSubnetDeploymentName}'

