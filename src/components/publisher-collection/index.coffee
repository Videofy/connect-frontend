mkCrudCollection = require('crud-collection')

PublisherCollection = mkCrudCollection
  baseUri: 'publisher'
  model: require('publisher-model')

module.exports = PublisherCollection
