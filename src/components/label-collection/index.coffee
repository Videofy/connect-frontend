mkCrudCollection = require('crud-collection')

LabelCollection = mkCrudCollection
  baseUri: 'label'
  model: require("label-model")

module.exports = LabelCollection
