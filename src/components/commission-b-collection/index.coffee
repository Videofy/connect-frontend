mkCrudCollection = require('crud-collection')

module.exports = mkCrudCollection
  baseUri: 'commission'
  model: require('commission-b-model')
