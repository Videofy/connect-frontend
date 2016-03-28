
TemplateRenderer = require("template-renderer")

class UsertypeEditorView extends Backbone.View

  className: "usertype-editor-view"

  events: 
    "change input.user-type": "onChangeType"

  initialize: ( opts ) ->
    @i18 = opts.i18
    @usertype = opts.usertype
    @renderer = new TemplateRenderer
      view: @
      template: require("./template")
      locals:
        strings: @i18.strings
        usertype: @usertype

  render: ->
    @renderer.render()

  setType: ( type ) ->
    @usertype.type = type.toLowerCase()
    @trigger("change")

  onChangeType: ->
    @setType(@el.querySelector("input.user-type").value)

module.exports = UsertypeEditorView
