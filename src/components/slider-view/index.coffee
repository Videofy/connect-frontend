View = require("view-plugin")

prevent = (e)->
  e.stopPropagation()
  e.preventDefault()
  e.returnValue = false

getPercentForMouse = (el, x) ->
  rect = el.getBoundingClientRect()
  (x - rect.left) / rect.width

SliderView = v = bQuery.view()

v.use View
  className: "slider-view"
  template: require("./template")

v.ons
  "mousedown .hitbox": "onDownHitbox"
  "mousemove .hitbox": "onMoveHitbox"
  "mouseup .hitbox": "onUpHitbox"

v.set "render", ->
  @renderer.render()
  @hitbox = @el.querySelector(".hitbox")
  @progress = @el.querySelector(".growth")

v.set "setPosition", (percent)->
  return if not @el.firstChild
  @progress.style.width = (percent * 100) + "%"

v.set "onDownHitbox", (e)->
  prevent(e)
  @active = true
  @trigger("slidestart", getPercentForMouse(@hitbox, e.pageX))

v.set "onMoveHitbox", (e)->
  if e.which isnt 1
    delete @active
  if @active
    prevent(e)
    p = getPercentForMouse(@hitbox, e.pageX)
    @setPosition(p)
    @trigger("slidemove", p)

v.set "onUpHitbox", (e)->
  prevent(e)
  delete @active
  p = getPercentForMouse(@hitbox, e.pageX)
  @setPosition(p)
  @trigger("slideend", p)

module.exports = v.make()
