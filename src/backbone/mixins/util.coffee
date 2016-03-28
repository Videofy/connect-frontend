
bQuery.view.mixin 'util', ->
  return (v) ->
    v.set "hide", (model, ns) ->
      if model
        model.trigger "hide", ns
        model.hidden = yes
      else
        @$el.hide()

    v.set "show", (model, ns) ->
      if model
        model.trigger "show", ns
        model.hidden = no
      else
        @$el.show()
