View = require("view-plugin")

createTab = (key, item, click)->
  li = document.createElement("li")
  li.textContent = item.title
  li.setAttribute("key", key)
  li.addEventListener("click", click)
  li

TabView = v = bQuery.view()

v.use View
  className: "tab-view"
  template: require("./template")

v.init (@config={}, @active)->

v.set "render", ->
  delete @content if @isowncontent
  Object.keys(@config).forEach (key)=> @config[key].rendered = false
  @renderer.render()
  cb = @onClickTab.bind(@)
  for k, v of @config
    @n.getEl("[role='tabs']").appendChild(createTab(k, v, cb))

  @setTab(@active, true) if @active

v.set "set", (config)->
  @config = config

v.set "setTab", (key, force)->
  if key is @active and not force and @config[key].rendered
    return false

  if not content = @content
    @isowncontent = true
    content = document.createElement("div")
    content.className = "content"
    @el.appendChild(content)
    @content = content

  while content.firstChild
    content.removeChild(content.firstChild)

  item = @config[key]
  if not item.rendered
    item.rendered = true
    item.view.render?()

  content.appendChild(item.view.el)

  if @n.getEl('ul')
    @n.evaluateClass("ul > [key='#{@active}']", "active", false) if @active
    @n.evaluateClass("ul > [key='#{key}']", "active", true)

  @active = key
  @trigger("changetab", key)
  true

v.set 'resetRendering', ->
  for key, item of @config
    item.rendered = false

v.set "hide", (key, value)->
  @n.evaluateClass("ul > [key='#{key}']", "hide", value)

v.set "onClickTab", (e)->
  return if not key = e.target.getAttribute("key")
  @setTab(key)

module.exports = v.make()
