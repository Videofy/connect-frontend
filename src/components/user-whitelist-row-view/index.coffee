Promise               = require('bluebird')
userWhitelist         = require("user-whitelist")
view                  = require("view-plugin")
WhitelistChannelsView = require("whitelist-channels-view")
SubscriptionModel     = require('subscription-model')
rowView               = require("row-view-plugin")

onClickLink = (e)->
  e.stopPropagation()

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
  return unless @model.get('subscriptionModelId') and !@subscription
  @subscription = new SubscriptionModel
    _id: @model.get("subscriptionModelId")

v.set "render", ->
  @renderer.locals.subscription = @subscription
  if @subscription
    @subscription.sfetch (err)=>
      @renderer.render()
  else
    @renderer.render()

module.exports = v.make()
