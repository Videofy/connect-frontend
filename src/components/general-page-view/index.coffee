View = require("view-plugin")

GeneralPageView = v = bQuery.view()

v.use View
  className: "general-page-view"
  template: require("./template")

v.init (opts={}) ->
  { @body, @template, @html } = opts

v.set "render", ->
  @renderer.render()
  content = @el.querySelector(".content")
  if @body
    @body.render()
    content.appendChild(@body.el)
  else if @template
    content.innerHTML = @template({})
  else if @html
    content.innerHTML = @html

module.exports = v.make()
