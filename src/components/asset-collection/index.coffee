mkCrudCollection = require('crud-collection')

module.exports = mkCrudCollection
  baseUri: 'asset'
  model: require('asset-model')