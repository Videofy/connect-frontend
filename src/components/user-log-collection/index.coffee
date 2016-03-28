eurl            = require('end-point').url
SuperCollection = require('super-collection')

class UserLogsCollection extends SuperCollection

  initialize: (models, opts={}) ->
    throw Error('You must provide a user.') unless opts.user
    @user = opts.user

  url: ->
    eurl("/logs/user/#{@user.id}")

module.exports = UserLogsCollection
