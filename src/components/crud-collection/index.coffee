eurl            = require('end-point').url
SuperCollection = require('super-collection')
SuperModel      = require('super-model')

module.exports = (config={})->
  throw Error('baseUri not defined.') unless config.baseUri

  if not config.model
    class CrudModel extends SuperModel
        urlRoot: "/api/#{config.baseUri}"
    config.model = CrudModel

  class CrudCollection extends SuperCollection

    model: config.model

    url: ->
      eurl((@urlRoot or '/api/' + config.baseUri) + @getQueryString())

    constructor: (models, opts={})->
      { @by, @query, @list, @fields } = opts
      @query ?= {}
      SuperCollection.prototype.constructor.call(@, models, opts)

    parse: (res)->
      if res instanceof Array
        @pagination =
          limit: res.length
          total: res.length
          skip: 0
        return res

      @pagination = _.pick(res, 'limit', 'total', 'skip')
      return res.results

    create: (attr={}, opts={})->
      attr["#{@by.key}"] = @by.value if @by
      SuperCollection.prototype.create.call(@, attr, opts)

    getQueryString: (query)->
      obj = _.clone(query or @query or {})

      if @by?
        obj.by_key = @by.key
        obj.by_value = @by.value

      if @list?
        obj.ids = @list.join(',')

      if @fields? and @fields.length
        obj.fields = @fields.join(',')

      str = Object.keys(obj)
        .map (key)->
          encodeURIComponent(key) + '=' + encodeURIComponent(obj[key])
        .join('&')
      if str then "?#{str}" else ''
