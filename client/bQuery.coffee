
class bQueryView
  constructor: (opts={}) ->
    bQueryView = ->

    @_events = []
    @_properties = []
    @_init = []
    @_view = opts.view or Backbone.View.extend(bQueryView)

  init: (f) ->
    @_init.push f
    @

  on: (e, f) ->
    @_events.push { name: e, fn: f }
    @

  ons: ( c ) ->
    for k, v of c
      @_events.push
        name: k
        fn: v
    @

  sets: (p, v) ->
    @view()[p] = v
    @

  set: (p, v) ->
    @_properties.push { name: p, value: v }
    @

  use: (p) ->
    p(@, @view)
    @

  view: (x) ->
    if x and _.isFunction(x)
      x(@_view)
      return @
    @_view

  make: (v) ->
    v = v or @view()

    # set up our events
    v::events = =>
      evts = {}
      groupedEvents = _.groupBy @_events, (e) -> e.name

      # group events with the same key and call them simultaneously
      for k, v of groupedEvents
        do (k, v) ->
          name = k
          fns = v
          if v.length > 1
            evts[k] = ->
              for { fn } in fns when typeof fn is 'function'
                fn.apply @, [].slice.call(arguments)
              return
          else
            [{ fn }] = fns
            evts[k] = fn
      return evts

    for { name, value } in @_properties
      v::[name] = value

    t = @
    v::initialize = (opts={}) ->
      i.call @, opts for i in t._init
      return

    v


class bQuery
  constructor: ->

  @view: -> new bQueryView

bQuery.view.mixin = (name, mixin) ->
  go = (n, m) ->
    unless bQuery.allowOverwrite
      if bQueryView::[n]
        throw "bQuery plugin with the name '#{ n }' already exists. Set bQuery.allowOverwrite = true to allow overwriting plugins"

    bQueryView::[n] = (xs...) -> @use m(xs...)

  if typeof name is 'object'
    for own key, val of name
      go key, val
  else
    go name, mixin

