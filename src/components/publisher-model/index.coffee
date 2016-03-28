SuperModel = require('super-model')

class PublisherModel extends SuperModel

  urlRoot: '/api/publisher'

  displayTitle: ->
    @attributes.name

module.exports = PublisherModel