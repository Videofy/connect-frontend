mkCrudCollection = require('crud-collection')

ReleaseCollection = mkCrudCollection
  baseUri: 'release'
  model: require('release-model')

module.exports = ReleaseCollection