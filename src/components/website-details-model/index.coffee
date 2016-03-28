SuperModel = require('super-model')

class WebsiteDetailsModel extends SuperModel
  urlRoot: '/api/website'

  profileImage: ->
    "#{@url()}/image"

module.exports = WebsiteDetailsModel
