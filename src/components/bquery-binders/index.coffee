
ap = require('ap')

isEmpty = (v) -> not v or (v and v.length is 0)

prop = (s) -> "input[property='#{s}']"

bound = module.exports =
  showWhen: (opts) ->
    return (v) -> v.conditionalShow(opts, false)

  showWhenEmpty: (opts) ->
    opts.pred = isEmpty
    return (v) -> v.showWhen opts

  hideWhenEmpty: (opts) ->
    opts.pred = isEmpty
    return (v) -> v.hideWhen opts

  hideWhen: (opts) ->
    return (v) -> v.conditionalShow(opts, true)

  conditional: (opts) ->
    return (v) ->
      opts.pred ?= _.identity
      v.bound opts.field, (m, newValue) ->
        $c = @$(opts.tag)
        if $c
          ok = opts.pred.call @, newValue
          if ok
            if opts.inv then opts.a($c) else opts.b($c)
          else
            if opts.inv then opts.b($c) else opts.a($c)

  conditionalShow: (opts, inv=false) ->
    return (v) ->
      if opts.visibility
        v.conditional _.extend(opts,
          a: ($c) -> $c.invisible()
          b: ($c) -> $c.visible()
          inv: inv
        )
      else
        v.conditional _.extend(opts,
          a: ($c) -> $c.hide()
          b: ($c) -> $c.show()
          inv: inv
        )

  boundText: (field, tag, fn) ->
    fn ?= (v) -> if v then v else "<#{ field } not set>"
    return (v) ->
      v.bound field, (m, nv) ->
        @$(tag).text(fn.call(@, nv))

  boundFromView: (field, tag, fromView) ->
    return (v) ->
      fromView ?= _.identity
      v.on "change #{ tag }", ->
        $tag = @$(tag)
        val = $tag.val()
        @model.set field, fromView(val, $tag)

  boundToView: (field, tag, toView) ->
    return (v) ->
      toView ?= _.identity
      v.bound field, (m, nv) ->
        $tag = @$(tag)
        $tag.val(toView(nv, $tag))


# bidirection val() binding
  boundPropVal: (field, opts={}) ->
    return (v) ->
      v.use(bound.boundVal(field, prop(field), opts))

  boundVal: (field, tag, opts={}) ->
    return (v) ->
      v.boundFromView field, tag, opts.fromView
      v.boundToView field, tag, opts.toView

  customBoundCheckbox: (opts={}) ->
    return (v) ->
      v.on "change #{opts.tag}", ->
        $tag = @$(opts.tag)
        checked = !!$tag.attr('checked')
        opts.handler.call(@, checked, $tag)

      v.bound opts.field, (m, nv) ->
        $tag = @$(opts.tag)
        if nv
          $tag.attr("checked", "checked")
        else
          $tag.removeAttr("checked")

  boundCheckbox: (field, tag, opts={}) ->
    return (v) ->
      v.customBoundCheckbox
        tag: tag
        field: field
        handler: (checked) ->
          @model.set field, checked
          @model.save()

  boundModel: (opts) ->
    opts ?= {}
    return (v) ->
      v.init ->
        model = ap.call @, opts.model
        # this should solve initial edge conditions
        unless opts.noInit
          @on "render", =>
            opts.update.call @, model, model.get(opts.field)
        model.on "change:#{ opts.field }", opts.update, @

  bound: (field, update, noInit=false) ->
    return (v) ->
      v.use bound.boundModel
        field: field
        model: -> @model
        update: update
        noInit: noInit

  boundAttr: (opts) ->
    return (v) ->
      v.bound opts.field, (m, nv) ->
        bval = _.beta.call @, opts.val, m, nv
        val = bval or nv
        @$(opts.tag).attr(opts.attr, val)
      , opts.noInit
