
$ -> _.templateSettings = interpolate: /\{\{(.+?)\}\}/g

#=----------------------------------------------------------------------------=#
# Underscore extensions
#=----------------------------------------------------------------------------=#
_.mixin({
  linkify: (l) ->
    [location.protocol, "//", window.location.hostname, l].join("")

  sum: (xs) -> _(xs).reduce ((a, b) -> a + b), 0

  just: (v) ->
    return -> v

  promise: (fn) ->
    event = {}
    _.extend(event, Backbone.Events)
    data = null
    ran = false
    d =
      run: ->
        ran = true
        fn (xs...) ->
          data = xs
          event.trigger "fetch", xs...
        d

      go: (cb) ->
        d.run() unless ran
        d.wait cb

      wait: (cb=(->)) ->
        return cb data... if data isnt null
        event.on "fetch", (xs...) ->
          return cb xs...
        d

  defined: (v) -> !_.isUndefined(v)
  exists: (v) -> v?

  anyThen: (f1, f2) ->
    called = false
    return (args...) ->
      unless called
        called = !!f1(args...)
      else
        f2 args...

  eq: (a, b) -> a is b

  beta: (fn, args...) -> if _.isFunction(fn) then fn.apply @, args else fn
})

#=----------------------------------------------------------------------------=#
# jQuery extensions
#=----------------------------------------------------------------------------=#
$.fn.enter = (cb) ->
  @keydown (e) ->
    if (e.which or e.keyCode) is 13
      e.preventDefault()
      cb e
      return false

$.fn.visible   = -> @css("visibility", "")
$.fn.disable   = -> @attr("disabled", "disabled")
$.fn.enable    = -> @removeAttr("disabled")
$.fn.invisible = -> @css("visibility", "hidden")

#=----------------------------------------------------------------------------=#
# bQuery extensions
#=----------------------------------------------------------------------------=#
bQuery.view.mixin({
  openFilteredViews: (o={}) ->
    return (v) ->
      v.init ->
        lastOpened = []
        @collection.on 'filter', (filtered) =>
          ids = _(filtered.model).pluck("id")
          _(lastOpened).each (lo) => lo.close(instantly: yes)

          if filtered.length <= (o.n or 3)
            views = _(o.views.call @).filter (v) -> v.model.id in ids
            _(views).each (v) => v.open(instantly: yes)
            lastOpened = views
})

#=----------------------------------------------------------------------------=#
# Mixins
#=----------------------------------------------------------------------------=#

Mixins = @Mixins = @Mixins or {}
@Mixins.defaults = @Mixins.defaults or {}

Views?.templates.get = (t) -> Mixins.makeAsyncTemplate Views.templates[t]

Mixins.ap = _.beta

Mixins.bq = {}
Mixins.bq.edit = {}
Mixins.collection = {}
Mixins.template = {}

Mixins.template.options = (xs, fnval, fnbody) ->
  co = require('codom')
  (_(xs).map (v) ->
    co.node("option", { value: fnval(v) }, fnbody(v))).join("")

#=----------------------------------------------------------------------------=#
# Mixins.log
#=----------------------------------------------------------------------------=#
Mixins.log = (logs...) ->
  console.log "log: ", logs... if console?.log?
  for log in logs
    alertify.log log

#=----------------------------------------------------------------------------=#
# Mixins.error
#=----------------------------------------------------------------------------=#
Mixins.success = (ss...) ->
  console.log "success! ", ss... if console?.log?
  for s in ss
    alertify.success s

#=----------------------------------------------------------------------------=#
# Mixins.error
#=----------------------------------------------------------------------------=#
Mixins.error = (errs...) ->
  console.log "ERR: ", errs... if console?.log?
  for err in errs
    alertify.error err

#=----------------------------------------------------------------------------=#
# Mixins.logError
#=----------------------------------------------------------------------------=#
Mixins.logError = Mixins.error

#=----------------------------------------------------------------------------=#
# Mixins.highestTrack
#=----------------------------------------------------------------------------=#
Mixins.highestTrack = ->
  Mixins.getHighestTrack @models.map((m) => m.get("trackNumber"))

Mixins.getHighestTrack = (ts) ->
  return 0 if ts.length is 0
  Math.max.apply null, (t or 0 for t in ts)

#=----------------------------------------------------------------------------=#
# Mixins.bq.required
#=----------------------------------------------------------------------------=#
bQuery.view.mixin.required = (msg) ->
  @

Mixins.confirm = (msg, cb) ->
  alertify.confirm msg, cb

Mixins.bq.delete = (tag, getMsg, cb) ->
  return (v) ->
    v.on "click #{ tag }", (e) ->
      defMsg = "Are you sure you want to delete this?"
      msg    = _.beta.call(@, getMsg) or defMsg

      if msg.name
        name = _.beta.call(@, msg.name)
        msg = "Are you sure you want to delete '#{ name }'?"

      Mixins.confirm msg, (yup) =>
        @model.destroy() if yup
        cb(yup,@) if cb

#=----------------------------------------------------------------------------=#
# mouseOver
#=----------------------------------------------------------------------------=#
Mixins.bq.mouseOver = (opts={}) ->
  return (v) ->
    over = (s) -> if !opts.tag then s else "#{s} #{opts.tag}"
    v.on over("mouseover"), opts.over
    v.on over("mouseout"), opts.out

#=----------------------------------------------------------------------------=#
# editMouseOver
#=----------------------------------------------------------------------------=#
Mixins.bq.editMouseOver = (tag) ->
  return (v) ->
    Mixins.bq.mouseOver(
      tag: tag
      over: (e) -> @$(tag).css("background-color", "#eee")
      out:  (e) -> @$(tag).css("background-color", "")
    )(v)

#=----------------------------------------------------------------------------=#
# Mixins.bq.mouseOvers
#   Show and hide mouseover effects
#=----------------------------------------------------------------------------=#
Mixins.bq.mouseOvers = (overElem, toggleElem, visibility=no, pred=(->yes)) ->
  unless overElem or toggleElem
    throw "missing overElement or togggleElement in bquery plugin 'mouseOvers'"
  show = if visibility then (x) -> x.visible() else (x) -> x.show()
  hide = if visibility then (x) -> x.invisible() else (x) -> x.hide()
  return (v) ->
    elem = (e) -> if _.isString toggleElem then e.$(toggleElem) else toggleElem
    over = (s) -> if !overElem then s else "#{s} #{overElem}"

    v.on over("mouseover"), ->
      e = elem(@)
      show(e) if pred.call @, "mouseover", e

    v.on over("mouseout"), ->
      e = elem(@)
      hide(e) if pred.call @, "mouseout", e

#=----------------------------------------------------------------------------=#
# Mixins.bq.fileUpload
#   TODO: Mixins.bq.fileUpload description
#=----------------------------------------------------------------------------=#
Mixins.bq.fileUpload = (opts) ->
  if opts == {} or opts is null
    throw "Invalid opts for File Upload Plugin"
  return (v) ->
    v.on "#{opts.event} #{opts.el}", (e) ->
      upload = $(e.target)
      $.each upload[0].files, (i, f) ->
        console.log f
        if f.type is 'image/jpeg' or f.type is 'image/gif'
          console.log "correct file type"

#=----------------------------------------------------------------------------=#
# Mixins.defaults.initTemplate
#   Some generic template loading logic for views
#=----------------------------------------------------------------------------=#
@Mixins.defaults.initTemplate = (name) ->
  template = Views?.templates?[name] or $("##{ name }-template").html()
  @template = _.template(template)


#=----------------------------------------------------------------------------=#
# Mixins.defaults.initialize
#=----------------------------------------------------------------------------=#
@Mixins.defaults.initialize = (name, opts={}) ->
  _.bindAll @, 'render'
  Mixins.defaults.initTemplate.call @, name
  Mixins.defaults.events.call @, opts


#=----------------------------------------------------------------------------=#
# Mixins.bq.initTemplate
#   standard template initialization
#=----------------------------------------------------------------------------=#
Mixins.bq.template = (name) ->
  return (v) ->
    v.init ->
      getTemplate = (n) ->
        Views?.templates?[n] or (-> $("##{ n }-template").html())

      template = getTemplate(name)
      newTemplate = getTemplate(name + "_new")

      if newTemplate
        @newTemplate = _.bind(Mixins.makeAsyncTemplate(newTemplate), @)

      if template

        @template = _.bind(Mixins.makeAsyncTemplate(template), @)


Mixins.bq.simpleTemplate = (template) ->
  return (v) ->
    v.set 'template', Mixins.makeAsyncTemplate(template)

#=----------------------------------------------------------------------------=#
# Mixin all the legacy Mixins.bq
#=----------------------------------------------------------------------------=#
_(Mixins.bq).each (fn, name) ->
  bQuery.view.mixin name, fn

#=----------------------------------------------------------------------------=#
# Mixins.chosen
#=----------------------------------------------------------------------------=#
Mixins.chosen = (finish, $edit) ->
  $select = $("select", $edit)
  $select = $edit if $select.length <= 0
  $select.chosen()
  $select.blur finish
  $(".chzn-container", $edit).mousedown()

#=----------------------------------------------------------------------------=#
# Mixins.chosenDropdown
#=----------------------------------------------------------------------------=#
Mixins.chosenDropdown = (finish, $edit, cb) ->
  $select = $("select", $edit)
  $select.chosen()
  $container = $(".chzn-container", $edit)
  noblur = yes
  $container.mousedown()
  $select.blur =>
    return if noblur is yes
    finish()
  cb()
  noblur = no


#=----------------------------------------------------------------------------=#
# Mixins.makeAsyncTemplate
#=----------------------------------------------------------------------------=#
Mixins.makeAsyncTemplate = (syncTemplate) ->
  return (data, cb) => cb(syncTemplate(data))



#=----------------------------------------------------------------------------=#
# OLD JUNK START
#=----------------------------------------------------------------------------=#
@Mixins.defaults.events = (opts={}) ->
  @model.bind "change", @render, @
  @model.bind "destroy", =>
    @$el.fadeOut =>
      unless opts.noDestroy
        @remove()
        @unbind()
  , @

@Mixins.defaults.simpleRender = ->
  html = @template(data: @model.toJSON())
  $(@el).html(html)
  @

@Mixins.defaults.render = ->
  Mixins.defaults.simpleRender.call @
  @closeBtn = @$(".close-btn")
  @

@Mixins.mouseOvers = (e, n="model", o=@closeBtn) ->
  elem = => if _.isFunction(o) then o() else o
  e["mouseover .#{ n }"] = => elem().show()
  e["mouseout .#{ n }"]  = => elem().hide()

#=----------------------------------------------------------------------------=#
# OLD JUNK END
#=----------------------------------------------------------------------------=#
