Promise    = require('bluebird')
parse      = require('parse')

addSharedMethods = (obj)->
  obj.sfetch = (opts, done)->
    done = opts unless done?
    opts.success = (obj, res, opts)->
      done(null, obj, res, opts)
    opts.error = (obj, res, opts)->
      done(parse.backbone.error(res), obj, res, opts)
    @fetch(opts)

  obj.isFetching = ->
    !!@fetching

  obj.invalidate = ->
    @hasSynced = false

  obj.sync = (method, model, options)->
    options ?= {}
    options.crossDomain = true
    options.xhrFields = withCredentials: true
    Backbone.sync(method, model, options)

toPromise = (isModel)-> (force)->
  promise = new Promise (resolve, reject) =>
    if @isNew() and isModel
      return resolve(@) unless force
      return @save {}, {success: resolve, error: reject}

    if force or @fetchIfNew?() or not @hasSynced
      @fetch() if force or (not @hasSynced and isModel)
      @once "error", reject
      @once "sync", resolve
    else
      if @lastResError
        return reject(@, @lastResErr)
      else
        return resolve(@, @lastRes)
  promise.toPromise = -> promise
  promise

fetchIfNew = ( success, failure ) ->
  if @isNew() and not @isFetchingNew
    @isFetchingNew = true
    @fetch
      success: =>
        if success
          success(@)
      error: =>
        if failure
          failure(@)
    return true
  else if @isFetchingNew
    return true
  false

module.exports = backbonePromises =
  construct: (obj, models)->
    obj.hasSynced = !!models
    obj.fetching = 0
    obj.on "request", =>
      obj.fetching++
    obj.on "error", (m, res) =>
      obj.fetching--
      obj.lastRes = res
      obj.lastResError = true
    obj.on "sync", (m, res) =>
      obj.fetching--
      obj.lastRes = res
    obj.once "reset sync", =>
      obj.hasSynced = true
      obj.isFetchingNew = false

  addCollectionMethods: (obj)->
    addSharedMethods(obj)
    obj.isNew = ->
      !@hasSynced
    obj.fetchIfNew = fetchIfNew
    obj.toPromise = toPromise(false)

  addModelMethods: (obj)->
    addSharedMethods(obj)
    obj.toPromise = toPromise(true)

