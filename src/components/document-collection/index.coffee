SuperCollection = require('super-collection')

class DocumentCollection extends SuperCollection

  urlRoot: '/documents'
  model: require('document-model')


module.exports = DocumentCollection
