
TemplateRenderer = require("template-renderer")

class PaneView extends Backbone.View

  tagName: "tr"

  className: "pane"

  initialize: ( opts ) ->
    @renderer = new TemplateRenderer
      view: @
      template: require("./template")
    @colspan = opts.colspan
    @body = opts.body

  delegateEvents: ->
    Backbone.View.prototype.delegateEvents.apply(this, arguments)
    if @body
      @body.delegateEvents()

  render: ->
    @renderer.render()
    td = @el.querySelector("td")
    if @colspan
      td.setAttribute("colspan", @colspan)
    if @body
      @body.render()
      td.appendChild(@body.el)

module.exports = PaneView
