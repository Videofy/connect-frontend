mkCrudCollection = require('crud-collection')

WhitelistCollection = mkCrudCollection
  baseUri: 'whitelist'
  model: require('whitelist-model')

module.exports = WhitelistCollection
