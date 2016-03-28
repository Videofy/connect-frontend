mkCrudCollection = require('crud-collection')

getContractable = ->
  @models.filter (user)->
    user.get('type').indexOf('artist') > -1 and !!user.get('name') and !!user.get('realName')

UserCollection = mkCrudCollection
  baseUri: 'user'
  model: require('user-model')

UserCollection.prototype.getArtists = getContractable
UserCollection.prototype.getContractable = getContractable
UserCollection.prototype.getContractViewable = ->
  @models.filter (user)->
    return false if !user.get('name') or !user.get('realName')
    _.intersection(user.get('type'), ['artist', 'admin', 'manager', 'label_admin']).length > 0

module.exports = UserCollection
