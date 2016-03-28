View = require("view-plugin")

prevent = (e)->
  e.preventDefault()
  e.stopPropagation()
  e.returnValue = false

getPosition = (x, y, target, boundary)->
  a = target.getBoundingClientRect()
  b = boundary.getBoundingClientRect()

  if x + a.width > b.width
    x = x - a.width
  if y + a.height > b.height
    y = y - a.height

  x: x
  y: y

ContextMenuView = v = bQuery.view()

v.use View
  className: "context-menu-view"
  template: require("./template")

v.ons
  "click li": "onClickItem"

v.init ->
  @cbs =
    click: @onClick.bind(@)

v.set "render", ->
  @renderer.render()

v.set "getItems", ->
  @renderer.locals.items or []

v.set "setItems", (items)->
  @renderer.locals.items = items

v.set "open", (originX=0, originY=0, source)->
  @trigger("open", source, @)

  return if @getItems().length is 0

  @render()
  @el.classList.add("open")
  document.querySelector("body").appendChild(@el)

  pos = getPosition(originX, originY, @el, document.body)
  @el.style.top = pos.y + "px"
  @el.style.left = pos.x + "px"

  window.addEventListener("wheel", prevent, false)
  document.addEventListener("wheel", prevent, false)
  document.addEventListener("keydown", prevent, false)
  document.addEventListener("mousedown", @cbs.click)

v.set "close", ->
  @el.remove()
  @el.classList.remove("open")
  window.removeEventListener("wheel", prevent)
  document.removeEventListener("wheel", prevent)
  document.removeEventListener("keydown", prevent)
  document.removeEventListener("mousedown", @cbs.click)
  @trigger("close", @)

v.set "onClickItem", (e)->
  prevent(e) if e.target.tagName.toLowerCase() isnt "a"
  @close()
  index = parseInt(e.currentTarget.getAttribute("index"))
  @trigger("select", @getItems()[index], @)

v.set "onClick", (e)->
  target = e.target
  while target
    return if target is @el
    target = target.parentElement
  @close()

module.exports = v.make()
