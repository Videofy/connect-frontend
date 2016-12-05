SuperModel        = require('super-model')
eurl              = require('end-point').url

class DocumentModel extends SuperModel
  urlRoot: '/document'

  downloadUrl: ->
    eurl("/document/dl/#{@id}")

module.exports = DocumentModel
