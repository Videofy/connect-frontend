parse = require('parse')
view  = require('view-plugin')
rowView = require('row-view-plugin')
disabler = require('disabler-plugin')

onClickLink = (e)->
  e.stopPropagation()

onClickDelete = (e)->
  e.stopPropagation()

  msg = @i18.strings.defaults.destroyMsg.replace(/\{.+\}/, @model.get("email"))
  return unless window.confirm(msg)

  @model.destroy
    wait: true
    error: (model, res)=>
      @toast(parse.backbone.error(res).message, "error")

UserRowView = v = bQuery.view()

v.use view
  className: "pane-row"
  tagName: "tr"
  template: require("./template")
  locals: ->
    canDelete: @permissions.canAccess('user.destroy')

v.use disabler
  attribute: 'editable'

v.use rowView

v.ons
  "click [role='link']": onClickLink
  "click [role='delete']": onClickDelete

v.set "render", ->
  @renderer.render()

module.exports = v.make()
