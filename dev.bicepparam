using 'main.bicep'

param application = 'howdy'

param environment = 'dev'

param location = 'southcentralus'

param maintenanceConfiguration = [
  {
    type: {
      name: 'windows'
      classificationsToInclude: [
        'Critical'
        'Security'
        'Definition'
      ]
    }
    duration: '01:30'
    rebootSetting: 'Always'
    recurrence: {
      name: 'daily'
    }
    startTime: '00:00'
    timeZone: 'Central Standard Time'
  }
  {
    type: {
      name: 'linux'
      classificationsToInclude: [
        'Critical'
        'Security'
        'Other'
      ]
    }
    duration: '01:30'
    rebootSetting: 'Always'
    recurrence: {
      name: 'monthly'
      frequency: '1'
      repeat: {
        name: 'specific day of month'
        day: 'Friday'
        offset: '0'
        week: 'First'
      }
    }
    startTime: '00:00'
    timeZone: 'Central Standard Time'
  }
]

param tags = {
  ExpirationDate: '12.12.2024'
  Owner: 'Brandon Treaster'
}
