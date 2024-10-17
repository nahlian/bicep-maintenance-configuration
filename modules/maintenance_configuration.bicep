@description('Azure region for deployment.')
param location string

@description('Maintenance configuration attributes.')
param maintenanceConfiguration maintenanceConfigurationType

@description('Azure resource name of maintenance configuration.')
param name string

@description('Current time in UTC.')
param now string = utcNow('yyyy-MM-dd HH:mm')

@description('Current year, month, and day.')
param todayDate string = utcNow('yyyy-MM-dd')

@description('Resource tags applied to all Azure resources.')
param tags object

@description('Configurations on maintenance name.')
var maintenanceConfigurationConfigMap = {
  daily: '1Day'
  hourly: maintenanceConfiguration.recurrence.name == 'hourly'
    ? '${maintenanceConfiguration.recurrence.frequency}Hour'
    : null
  weekly: maintenanceConfiguration.recurrence.name == 'weekly'
    ? weeklyRecurrenceFunc(maintenanceConfiguration.recurrence)
    : null
  monthly: maintenanceConfiguration.recurrence.name == 'monthly'
    ? monthlyRecurrenceFunc(maintenanceConfiguration.recurrence)
    : null
}

@description('Start time for maintenance.')
var updateStartTime = dateTimeAdd(
  '${todayDate} ${maintenanceConfiguration.startTime}',
  dateTimeToEpoch('${todayDate} ${maintenanceConfiguration.startTime}') > dateTimeToEpoch(now) + 300 ? 'P0D' : 'P1D',
  'yyyy-MM-dd HH:mm'
)

resource maintenance_configuration 'Microsoft.Maintenance/maintenanceConfigurations@2023-10-01-preview' = {
  location: location
  name: name
  tags: tags
  properties: {
    extensionProperties: {
      InGuestPatchMode: 'User'
    }
    installPatches: {
      linuxParameters: maintenanceConfiguration.type.name == 'linux'
        ? {
            classificationsToInclude: maintenanceConfiguration.type.classificationsToInclude
          }
        : {}
      rebootSetting: maintenanceConfiguration.rebootSetting
      windowsParameters: maintenanceConfiguration.type.name == 'windows'
        ? {
            classificationsToInclude: maintenanceConfiguration.type.classificationsToInclude
          }
        : {}
    }
    maintenanceScope: 'InGuestPatch'
    maintenanceWindow: {
      duration: maintenanceConfiguration.duration
      recurEvery: maintenanceConfigurationConfigMap[maintenanceConfiguration.recurrence.name]
      startDateTime: updateStartTime
      timeZone: maintenanceConfiguration.timeZone
    }
    visibility: 'Custom'
  }
}

@description('Function that formats string required for monthly maintenance.')
func monthlyRecurrenceFunc(monthlyRecurrence monthlyRecurrenceType) string =>
  monthlyRecurrence.repeat.name == 'day of month'
    ? '${monthlyRecurrence.frequency}Month ${join(map(range(0, length(monthlyRecurrence.repeat.day)), d => 'day${monthlyRecurrence.repeat.day[d]}'), ',')}'
    : trim('${monthlyRecurrence.frequency}Month ${monthlyRecurrence.repeat.week} ${monthlyRecurrence.repeat.day} ${monthlyRecurrence.repeat.offset == '0' ? null : 'Offset${monthlyRecurrence.repeat.offset}'}')

@description('Function that formats string required for weekly maintenance.')
func weeklyRecurrenceFunc(weeklyRecurrence weeklyRecurrenceType) string =>
  '${weeklyRecurrence.frequency}Week ${length(weeklyRecurrence.day) > 1 ? join(weeklyRecurrence.day, ',') : weeklyRecurrence.day[0]}'

@description('Daily maintenance configuration.')
type dailyRecurrenceType = {
  name: 'daily'
}

@description('Linux maintenance configuration attributes.')
type linuxMaintenanceConfigurationType = {
  name: 'linux'

  @description('Classification category of patches to be installed.')
  classificationsToInclude: ('Critical' | 'Security' | 'Other')[]
}

@description('Hourly maintenance configuration.')
type hourlyRecurrenceType = {
  name: 'hourly'

  @description('How often the maintenance occurs. Value must be between 6 and 35.')
  frequency: (
    | '6'
    | '7'
    | '8'
    | '9'
    | '10'
    | '11'
    | '12'
    | '13'
    | '14'
    | '15'
    | '16'
    | '17'
    | '18'
    | '19'
    | '20'
    | '21'
    | '22'
    | '23'
    | '24'
    | '25'
    | '26'
    | '27'
    | '28'
    | '29'
    | '30'
    | '31'
    | '32'
    | '33'
    | '34'
    | '35')
}

@export()
@description('Maintenance configuration attributes.')
type maintenanceConfigurationType = {
  @discriminator('name')
  @description('Operating system type.')
  type: (linuxMaintenanceConfigurationType | windowsMaintenanceConfigurationType)

  @description('Duration of the maintenance window.')
  duration: ('01:30' | '02:00' | '02:30' | '03:00' | '03:55')

  @description('Decides to reboot the machine or not after the patch operation is completed.')
  rebootSetting: ('Always' | 'IfRequired' | 'Never')

  @discriminator('name')
  @description('Rate at which a Maintenance window is expected to recur.')
  recurrence: (hourlyRecurrenceType | dailyRecurrenceType | monthlyRecurrenceType | weeklyRecurrenceType)

  @description('Start time for maintenance.')
  startTime: (
    | '00:00'
    | '01:00'
    | '02:00'
    | '03:00'
    | '04:00'
    | '05:00'
    | '06:00'
    | '07:00'
    | '08:00'
    | '09:00'
    | '10:00'
    | '11:00'
    | '12:00'
    | '13:00'
    | '14:00'
    | '15:00'
    | '16:00'
    | '17:00'
    | '18:00'
    | '19:00'
    | '20:00'
    | '21:00'
    | '22:00'
    | '23:00')

  @description('Time zone where resource is deployed. https://jackstromberg.com/2017/01/list-of-time-zones-consumed-by-azure/')
  timeZone: ('Eastern Standard Time' | 'Central Standard Time' | 'Mountain Standard Time' | 'Pacific Standard Time')
}

@description('Monthly maintenance configuration.')
type monthlyRecurrenceType = {
  name: 'monthly'

  @description('How often the maintenance occurs. One equals every month, two every other month, etc.')
  frequency: ('1' | '2' | '3' | '4')

  @discriminator('name')
  @description('Repeat based off day number or a specific day of the month.')
  repeat: (monthlyRepeatDayNumberType | monthlyRepeatSpecificDayType)
}

@description('Monthly schedule based on day of the month.')
type monthlyRepeatDayNumberType = {
  name: 'day of month'

  @description('Days of month to run maintenance. The "-1" is the last day of the month.')
  day: (
    | '1'
    | '2'
    | '3'
    | '4'
    | '5'
    | '6'
    | '7'
    | '8'
    | '9'
    | '10'
    | '11'
    | '12'
    | '13'
    | '14'
    | '15'
    | '16'
    | '17'
    | '18'
    | '19'
    | '20'
    | '21'
    | '22'
    | '23'
    | '24'
    | '25'
    | '26'
    | '27'
    | '28'
    | '29'
    | '30'
    | '31'
    | '-1')[]
}

@description('Monthly schedule based on specific day of the month.')
type monthlyRepeatSpecificDayType = {
  name: 'specific day of month'

  @description('Day of the week to run the maintenance.')
  day: ('Monday' | 'Tuesday' | 'Wednesday' | 'Thursday' | 'Friday' | 'Saturday' | 'Sunday')

  @description('Run maintenance prior or after the day of week specified.')
  offset: ('-6' | '-5' | '-4' | '-3' | '-2' | '-1' | '0' | '1' | '2' | '3' | '4' | '5' | '6')

  @description('Week of the month for maintenance to run.')
  week: ('First' | 'Second' | 'Third' | 'Fourth' | 'Last')
}

@description('Weekly maintenance configuration.')
type weeklyRecurrenceType = {
  name: 'weekly'

  @description('Days of the week to run the maintenance.')
  day: ('Monday' | 'Tuesday' | 'Wednesday' | 'Thursday' | 'Friday' | 'Saturday' | 'Sunday')[]

  @description('How often the maintenance occurs. One equals every week, two every other week, etc.')
  frequency: ('1' | '2' | '3' | '4')
}

@description('Linux maintenance configuration attributes.')
type windowsMaintenanceConfigurationType = {
  name: 'windows'

  @description('Classification category of patches to be installed.')
  classificationsToInclude: (
    | 'Critical'
    | 'Definition'
    | 'FeaturePack'
    | 'Security'
    | 'ServicePack'
    | 'Tools'
    | 'UpdateRollup'
    | 'Updates')[]
}

@description('Azure resource ID of security maintenance configuration.')
output securityMaintenanceId string = maintenance_configuration.id
