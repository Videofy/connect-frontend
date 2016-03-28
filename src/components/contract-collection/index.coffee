SuperCollection = require('super-collection')

class ContractCollection extends SuperCollection

  urlRoot: '/api/contracts'

  model: require('contract-model')

module.exports = ContractCollection
