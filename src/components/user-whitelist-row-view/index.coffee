Promise               = require('bluebird')
userWhitelist         = require("user-whitelist")
view                  = require("view-plugin")
WhitelistChannelsView = require("whitelist-channels-view")
SubscriptionModel     = require('subscription-model')
rowView               = require("row-view-plugin")
parse                 = require("parse")

onClickDelete = (e)->
  e.stopPropagation()
  msg = @i18.strings.defaults.destroyMsg.replace(/\{.+\}/, 'this whitelist ' + @model.get('identity'))
  return unless window.confirm(msg)

  if @model.hasSubscription()
    return unless window.confirm(@i18.strings.whitelist.confirmDeleteSubscription)

  @model.destroy
    wait: true
    # Neither of these toasts work and I don't know why
    # This destroy also doesn't update the parent table view to remove the item
    success: (model, res, obj)=>
      @toast('Whitelist removed', 'success')
    error: (model, res, obj)=>
      @toast(parse.backbone.error(err).message, 'error')

UserWhitelistRowView = v = bQuery.view()

v.use view
  className: "pane-row"
  tagName: "tr"
  template: require("./template")

v.use rowView

v.ons
  "click [role='delete']": onClickDelete

v.init (opts={})->

v.set "render", ->
  @renderer.locals.model = @model
  @renderer.render()

module.exports = v.make()
