#debug                = require('debug')('connect:whitelist-model')
parse                = require('parse')
request              = require('superagent')
SuperModel           = require('super-model')

class Whitelist extends SuperModel

  urlRoot: '/api/whitelist'

  hasSubscription: ()->
   !!@subscriptionId

module.exports = Whitelist