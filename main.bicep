targetScope = 'subscription'

import { maintenanceConfigurationType } from './modules/maintenance_configuration.bicep'

@description('Name of application or project running on these Azure resources.')
param application string

@allowed([
  'dev'
  'tst'
  'prd'
])
@description('Release environment.')
param environment string

@allowed([
  'centralus'
  'eastus'
  'eastus2'
  'northcentralus'
  'southcentralus'
  'usgovarizona'
  'usgovtexas'
  'usgovvirginia'
  'westcentralus'
  'westus'
  'westus2'
])
@description('Azure region of deployment.')
param location string

@description('Maintenance configuration attributes.')
param maintenanceConfiguration maintenanceConfigurationType[]

@description('Tags to add to the resource being deployed.')
param tags object

@description('Abbreviation for Azure region of deployment.')
var locationShort = {
  centralus: 'cus'
  eastus: 'eus'
  eastus2: 'eus2'
  northcentralus: 'nsu'
  southcentralus: 'scu'
  usgovarizona: 'usga'
  usgovtexas: 'usgt'
  usgovvirginia: 'usgv'
  westcentralus: 'wcu'
  westus: 'wus'
  westus2: 'wus2'
}

@description('Standard naming used for all resource names.')
var namingPrefix = '${locationShort[location]}-${environment}-${application}'

resource existing_resource_group 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: 'rg-County-TX-Bexar-Dev'
}

module maintenance_configuration 'modules/maintenance_configuration.bicep' = [
  for (a, i) in maintenanceConfiguration: {
    name: i < 10 ? 'maintenance_configuration_0${i + 1}' : 'maintenance_configuration_${i}'
    scope: existing_resource_group
    params: {
      location: location
      tags: tags
      maintenanceConfiguration: {
        duration: maintenanceConfiguration[i].duration
        rebootSetting: maintenanceConfiguration[i].rebootSetting
        recurrence: maintenanceConfiguration[i].recurrence
        startTime: maintenanceConfiguration[i].startTime
        timeZone: maintenanceConfiguration[i].timeZone
        type: maintenanceConfiguration[i].type
      }
      name: i < 10
        ? '${namingPrefix}-${maintenanceConfiguration[i].type.name}-mc-0${i + 1}'
        : '${namingPrefix}-${maintenanceConfiguration[i].type.name}-mc-${i}'
    }
  }
]

resource configuration_assignment 'Microsoft.Maintenance/configurationAssignments@2023-10-01-preview' = [
  for (c, i) in maintenanceConfiguration: {
    name: i < 10
      ? '${namingPrefix}-${maintenanceConfiguration[i].type.name}-ca-0${i + 1}'
      : '${namingPrefix}-${maintenanceConfiguration[i].type.name}-ca-${i}'
    properties: {
      filter: {
        locations: []
        osTypes: [
          maintenanceConfiguration[i].type.name
        ]
        resourceGroups: [existing_resource_group.name]
        resourceTypes: [
          'microsoft.compute/virtualmachines'
          'microsoft.hybridcompute/machines'
        ]
      }
      maintenanceConfigurationId: maintenance_configuration[i].outputs.securityMaintenanceId
    }
  }
]
