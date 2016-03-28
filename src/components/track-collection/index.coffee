mkCrudCollection = require('crud-collection')

TrackCollection = mkCrudCollection
  baseUri: 'track'
  model: require('track-model')

module.exports = TrackCollection
