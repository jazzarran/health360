// *** Parameters *** //
@allowed([
  'qa'
  'uat'
  'prod'
])
param environment string
param location string = resourceGroup().location
param deploymentTime string = utcNow()

// Parameters (Storage Account)
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS' 
])
param storageSKU string = 'Standard_LRS'

// Parameters (Virtual Machine)
param adminUsername string
param adminSshKey string
param dnsNameForPublicIP string

// *** Variables *** //
var projectName = 'health360'

var tags = {
  CostCenter: 'Health360R&D'
  Environment: toUpper(environment)
  Project: toUpper(projectName)
}

// Variables (Resource Specific)
var storageAccountDeploymentName = '${projectName}-storage-account-${deploymentTime}'
var virtualMachineDeploymentName = '${projectName}-appvm1-${deploymentTime}'
var virtualNetworkDeploymentName = '${projectName}-vnet-${deploymentTime}'
var postgresDbDeploymentName = '${projectName}-postgresdb-${deploymentTime}'

// Modules
module virtualNetwork '../modules/VirtualNetwork/main.bicep' = {
  name: virtualNetworkDeploymentName
  params: {
    location: location
    projectName: projectName
    environment: environment
    tags: tags
    dnsNameForAppsPublicIP: dnsNameForPublicIP
  }
}

module storageAcount '../modules/StorageAccount/main.bicep' = {
  name: storageAccountDeploymentName
  params: {
    location: location
    projectName: projectName
    environment: environment
    tags: tags
    sku: storageSKU
  }
}

module virtualMachine '../modules/VirtualMachine/main.bicep' = {
  name: virtualMachineDeploymentName
  params: {
    location: location
    projectName: projectName
    environment: environment
    tags: tags
    appsNicResourceId: virtualNetwork.outputs.appsNicResourceId
    vmAdminUsername: adminUsername
    vmAdminSshKey: adminSshKey
  }
  dependsOn: [
    virtualNetwork
  ]
}

module postgresDB '../modules/Database/main.bicep' = {
  name: postgresDbDeploymentName
  params: {
    location: location
    projectName: projectName
    environment: environment
    tags: tags
    dbSubnetId: virtualNetwork.outputs.dbSubnetResourceId
    administratorLogin: 'dbadmin'
    administratorLoginPassword: 'Password!'
  }
}
