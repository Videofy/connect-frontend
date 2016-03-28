{
  User,
  Track
} = require('contract-assets')

module.exports =
  getType: (obj)->
    map =
      user: User
      track: Track
      date: Date

    for k, v of map
      return k if obj instanceof v

    return typeof obj

  dummyForType: (type)->
    if type is 'string'
      return ''
    if type is 'number'
      return 0
    if type is 'date'
      return new Date
    if type is 'user'
      return new User
    if type is 'track'
      return new Track
    return undefined
