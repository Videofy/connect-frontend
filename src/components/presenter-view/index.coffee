View = require("view-plugin")
find = require("find-target-node")

delay = (context, ev, time=250)->
  setTimeout ->
    context.trigger ev
  , time

PresenterView = v = bQuery.view()

v.use View
  className: "presenter-view"
  template: require("./template")

v.ons
  "click": "onClick"

v.set "render", ->
  @renderer.render()

v.set "attach", (parent)->
  return if @el.parentElement
  parent = parent or document.body
  parent.appendChild(@el)
  @trigger "attach"

v.set "dettach", ->
  @el.remove()
  @trigger "dettach"

v.set "open", (view)->
  el = view.el or view
  @render()
  content = @n.getEl(".content").appendChild(el)
  @el.classList.add("open")
  @trigger("open:start")
  delay(@, "open:end")

v.set "close", ->
  @el.classList.remove("open")
  @trigger("close:start")
  delay(@, "close:end")

v.set "onClick", (e)->
  content = @n.getEl(".content")
  parent = find e.target, (target)-> target is content
  return if parent
  @close()

module.exports = v.make()
