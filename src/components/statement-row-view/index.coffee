TemplateRenderer = require("template-renderer")

class StatementRowView extends Backbone.View
  tagName: "tr"

  initialize: ( opts ) ->
    @i18 = opts.i18
    @renderer = new TemplateRenderer
      view: @
      template: require("./template")
      locals:
        strings: @i18.strings

  render: ->
    @renderer.render()

module.exports = StatementRowView
