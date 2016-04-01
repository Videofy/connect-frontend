SuperCollection = require('super-collection')
eurl            = require('end-point').url

class UserWhitelistCollection extends SuperCollection
  initialize: (models, opts={}) ->
    @user = opts.user
  
  model: require('whitelist-item-model')
  url: -> eurl("/user/whitelist/items/#{ @user.id }")

module.exports = UserWhitelistCollection
