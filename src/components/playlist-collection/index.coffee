mkCrud = require("crud-collection")
PlaylistModel = require("playlist-model")

PlaylistCollection = mkCrud
  baseUri: 'playlist'
  model: PlaylistModel

module.exports = PlaylistCollection
