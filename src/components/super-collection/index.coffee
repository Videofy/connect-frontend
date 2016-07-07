eurl                 = require('end-point').url
point                = require('point')
sortutil             = require('sort-util')
SuperModel           = require('super-model')
backbonePromises     = require('backbone-promises')

class SuperCollection extends Backbone.Collection

  model: SuperModel

  url: ->
    eurl(@urlRoot)

  constructor: (models, options)->
    Backbone.Collection.prototype.constructor.apply(this, arguments)
    backbonePromises.construct(@, models)
    @

  subCollection: (filter=->true)->
    collection = new SuperCollection
    collection.models = @models.filter(filter)
    collection.toPromise = (force)=> @toPromise(force).then =>
      collection.reset(@models.filter(filter))
    delete collection.fetching
    delete collection.hasSynced
    delete collection.fetchIfNew
    delete collection.isNew
    delete collection.isFetching
    collection

  getModelForPropertyValue: ( property, value ) ->
    for model in @models
      if model.get(property) is value
        return model
    return undefined

  getPage: (opts)->
    { filter, sort, range } = opts

    models = @models.slice()

    if filter
      models = models.filter(filter)

    if sort
      order = if sort.mode is 'desc' then 1 else -1
      sfunc =
        if typeof sort.field is 'function'
          (a, b)->
            sort.field(a, b) * order
        else
          sortutil.modeldl(sort.type, sort.field, order)
      models.sort(sfunc)

    if range
      start = point.clamp(range.start, 0, models.length)
      end = point.clamp(range.start + range.increment, 0, models.length)
      range.total = models.length
      models = models.slice(start, end)

    models

  addIds: (ids)->
    promise = new Promise (resolve, reject) =>
      ids = [ids] unless Array.isArray(ids)
      models = ids.filter((id)=>!@get(id)).map (id)=> new @model(_id: id)
      unless models.length
        return resolve()

      fetched = 0
      check = (err)=>
        return reject(err) if err
        fetched++
        if fetched is models.length
          @add(models)
          resolve()

      models.forEach (model)=>
        model.sfetch(check)

    promise

backbonePromises.addCollectionMethods(SuperCollection.prototype)

module.exports = SuperCollection
