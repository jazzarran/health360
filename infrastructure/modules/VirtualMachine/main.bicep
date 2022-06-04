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

param vmSize string = 'Standard_F1'
@allowed([
  '14.04.5-LTS'
  '16.04-LTS'
  '18.04-LTS'
])
param ubuntuOSVersion string = '18.04-LTS'
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'sshPublicKey'
param vmAdminUsername string
@secure()
param vmAdminSshKey string
param appsNicResourceId string

// *** Variables *** //
var imagePublisher = 'Canonical'
var imageOffer = 'UbuntuServer'
var dockerExtensionDeploymentName = 'DockerExtension'
var diskStorageType = 'Standard_LRS'
var vmDeploymentName = '${projectName}-app-vm-${locationMapping[toLower(location)]}-${environment}'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${vmAdminUsername}/.ssh/authorized_keys'
        keyData: vmAdminSshKey
      }
    ]
  }
}

// Resource (Imports)
resource primaryVNET 'Microsoft.Network/virtualNetworks@2019-11-01' existing = {
  name: 'primaryVirtualNetwork'
}

// Resources
resource appsVM1 'Microsoft.Compute/virtualMachines@2019-12-01' = {
  name: vmDeploymentName
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmDeploymentName
      adminUsername: vmAdminUsername
      adminPassword: vmAdminSshKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: ubuntuOSVersion
        version: 'latest'
      }
      osDisk: {
        name: '${vmDeploymentName}_osdisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: diskStorageType
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: appsNicResourceId
        }
      ]
    }
  }
}

resource vmDockerExtension 'Microsoft.Compute/virtualMachines/extensions@2019-12-01' = {
  parent: appsVM1
  name: dockerExtensionDeploymentName
  location: location
  tags: tags
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'DockerExtension'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
  }
}
