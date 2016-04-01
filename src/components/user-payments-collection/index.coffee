SuperCollection = require('super-collection')
SuperModel      = require('super-model')
eurl            = require('end-point').url

class UserPaymentsCollection extends SuperCollection

  model: SuperModel

  initialize: (models, opts={}) ->
    throw Error('You must provide a subscription.') unless opts.subscription
    @subscription = opts.subscription

  url: -> eurl("/subscription/payments/#{ @subscription.id }")

module.exports = UserPaymentsCollection
