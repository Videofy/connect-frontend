SuperCollection = require('super-collection')

class UserWhitelistCollection extends SuperCollection
  initialize: (models, opts={}) ->
    @user = opts.user
  
  model: require('whitelist-item-model')
  url: ->"/user/whitelist/items/#{ @user.id }"

module.exports = UserWhitelistCollection
