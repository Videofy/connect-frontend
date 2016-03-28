datetime             = require("date-time")
eurl                 = require('end-point').url
lens                 = require('dot-lens')
backbonePromises     = require('backbone-promises')

class SuperModel extends Backbone.Model

  idAttribute: '_id'

  url: ->
    eurl(Backbone.Model.prototype.url.call(@))

  constructor: ->
    Backbone.Model.prototype.constructor.apply(@, arguments)
    backbonePromises.construct(@)

  update: ->
    @save.apply(@, Array.prototype.slice.call(arguments)) if not @isNew()

  getAsFormatedDate: (property, format="M j, Y")->
    try
      field = lens(property).get(@attributes)
    catch e
      return ''

    if field instanceof Date
      return datetime.format(format, field)

    if typeof field is 'string' and datetime.isIsoString(field)
      return datetime.format(format, new Date(field))

    ''

  getDateStr: (property, format)->
    @getAsFormatedDate(property, format)

backbonePromises.addModelMethods(SuperModel.prototype)

module.exports = SuperModel
