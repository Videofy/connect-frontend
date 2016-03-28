SuperCollection = require('super-collection')
SuperModel      = require('super-model')

class UserPaymentsCollection extends SuperCollection

  model: SuperModel

  initialize: (models, opts={}) ->
    throw Error('You must provide a subscription.') unless opts.subscription
    @subscription = opts.subscription

  url: ->"/subscription/payments/#{ @subscription.id }"

module.exports = UserPaymentsCollection
