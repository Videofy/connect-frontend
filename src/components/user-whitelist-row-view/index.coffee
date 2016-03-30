Promise               = require('bluebird')
userWhitelist         = require("user-whitelist")
view                  = require("view-plugin")
WhitelistChannelsView = require("whitelist-channels-view")
SubscriptionModel     = require('subscription-model')
rowView               = require("row-view-plugin")

onClickLink = (e)->
  e.stopPropagation()

isWhitelistActive = (user)->
  result = true
  (user.whitelist or []).forEach (item)->
    result = false unless item.active
  result

UserWhitelistRowView = v = bQuery.view()

v.use view
  className: "pane-row"
  tagName: "tr"
  template: require("./template")

v.use rowView

v.ons
  "click [role='link']": onClickLink

v.init (opts={})->
  { @subscription } = opts
  @model.on "change", @render.bind(@)

  unless @subscription
    @subscription = new SubscriptionModel
      _id: @model.get('subscriptionModelId')

v.set "getSubscriptionModel", (next)->
  return next() unless @subscription.get('_id')

  @subscription.fetch
    success: next

v.set "render", ->
  @getSubscriptionModel ()=>
    @renderer.locals.inactive = @model.requiresSubscription(@subscription)
    @renderer.locals.subscriptionActive = not @model.requiresSubscription(@subscription)
    @renderer.locals.whitelistActive = isWhitelistActive(@model)
    @renderer.render()

module.exports = v.make()
