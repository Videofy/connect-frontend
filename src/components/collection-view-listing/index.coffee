Emitter = require("emitter")
KeyValueMap = require('key-value-map')

class CollectionViewListing

  constructor: ( config ) ->
    @needle = null
    @filters = []
    @delay = config.delay or 200
    @timer = -1
    @views = new KeyValueMap()
    @cache = new KeyValueMap()
    @states = new KeyValueMap()
    @collection = config.collection
    @createViewsForModel = config.createViewsForModel
    @predicateNeedle = config.predicateNeedle
    @compareModels = config.compareModels || -> 0
    @siftModel = config.siftModel || -> false
    @interval = config.initialLimit || 100
    @resultCount = @collection.length
    @setRange(0, @interval)
    @setEl(config.el)
    # INFO Break this into sub components?
    @setMoreEl(config.moreEl)
    @setInputEl(config.inputEl)
    @addListeners()

  setEl: ( el ) ->
    @empty()
    @el = el

  setInputEl: ( el ) ->
    if @inputEl
      @inputEl.removeEventListener("input", @onInputResponder)
    if el
      @inputEl = el
      @onInputResponder = @onInput.bind(@)
      @inputEl.addEventListener("input", @onInputResponder)
      @sift(@inputEl.value)
    else
      @sift("")

  setMoreEl: ( el ) ->
    if @moreEl
      @moreEl.removeEventListener("click", @onMoreResponder)
    if el
      @moreEl = el
      @onMoreResponder = @onMore.bind(@)
      @moreEl.addEventListener("click", @onMoreResponder)

  setRange: ( offset, limit ) ->
    @offset = offset
    @limit = limit

  getViews: ->
    @views.values

  getViewsForModel: ( model ) ->
    views = @cache.get(model) or null
    if not views and @createViewsForModel
      views = @createViewsForModel(model) or null
      if views && views.default
        @cache.set(model, views)
        @states.set(model, {
          visible: {
            "default":true
          },
          rendered: {
            "default":true
          }
        })
        views.default.render()
    views

  getModelForEl: ( el ) ->
    for views in @views.values
      if views.default.el == el
        return views.default.model

  getNumResults: ->
    @resultCount

  getNumResultsDisplaying: ->
    @views.keys.length

  canShowMore: ->
    @limit < @resultCount

  showMore: ( num=@interval ) ->
    count = @collection.length
    if @limit < count
      total = @limit + num
      if total > count
        total = count
      @setRange(0, total)
      @sift(@needle)

  updateMoreElState: ->
    return if !@moreEl

    style = if @canShowMore() then "" else "none"
    @moreEl.style.display = style

  sift: ( needle ) ->
    models = @collection.models.concat()
    nModels = []
    sneedle = @predicateNeedle?(needle) or needle

    if @compareModels
      models = models.sort(@compareModels)

    for model, i in models
      flag = false
      for filter in @filters
        if filter.match(model.get(filter.property), model)
          flag = true
          break
      if @siftModel(model, sneedle)
        flag = true
      if !flag
        nModels.push(model)

    models = nModels
    count = models.length

    # Store actual results.
    @resultModels = models.concat()
    @resultCount = @resultModels.length

    offset = @offset
    limit = @limit
    if offset > count
      offset = count - limit
    if offset < 0
      offset = 0
    if limit > count
      limit = count

    models = models.splice(offset, limit)
    oViews = @views
    nViews = new KeyValueMap()
    frag = document.createDocumentFragment()

    for model in models
      views = @views.get(model) || @getViewsForModel(model)
      if views
        oViews.delete(model)
        nViews.set(model, views)
        for name, view of views
          if @states.get(model).visible[name]
            frag.appendChild(view.el)
    if frag.hasChildNodes()
      @el.appendChild(frag)

    for model in oViews.keys
      views = oViews.get(model)
      for name, view of views
        view.el.remove()

    @views = nViews
    @needle = needle
    @updateMoreElState()
    @emit("sifted")

  empty: ->
    for model in @views.keys
      views = @views.get(model)
      for name, view of views
        view.remove()
    @views = new KeyValueMap()

  addPropertyFilter: ( property, match ) ->
    @filters.push
      property: property
      match: match

  removePropertyFilter: ( property, match ) ->
    for filter, i in @filters
      if filter.property == property and filter.match == match
        @filters.splice(i, 1)

  clearPropertyFilters: ->
    @filters = []

  clearViewCache: ->
    @cache = new KeyValueMap()

  addListeners: ->
    @collection.on "reset add remove", =>
      @sift(@needle)

  removeListeners: ->
    @collection.off "reset add remove"

  toggleView: ( name, model ) ->
    views = @views.get(model)
    if views and view = views[name]
      if view.el.parentElement
        view.el.parentElement.removeChild(view.el)
        @states.get(model).visible[name] = false
      else
        states = @states.get(model)
        states.visible[name] = true
        if !states.rendered[name]
          states.rendered[name] = true
          view.render()
        @el.insertBefore(view.el, views.default.el.nextSibling)

  openView: ( name, model ) ->
    views = @views.get(model)
    if views and view = views[name]
      states = @states.get(model)
      states.visible[name] = true
      if !states.rendered[name]
        states.rendered[name] = true
        view.render()
      @el.insertBefore(view.el, views.default.el.nextSibling)

  closeView: ( name, model ) ->
    views = @views.get(model)
    if views and view = views[name]
      view.el.parentElement.removeChild(view.el)
      @states.get(model).visible[name] = false

  onInput: ->
    if @timer != -1
      clearTimeout(@timer)
    @timer = setTimeout( =>
        @sift(@inputEl.value)
      , @delay)

  onMore: ->
    @showMore()
    @updateMoreElState()

Emitter(CollectionViewListing.prototype)

module.exports = CollectionViewListing
