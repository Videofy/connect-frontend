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
  @model.on "change", @render.bind(@)
  @subscriptionModel = new SubscriptionModel

  if @model.get('subscriptionModelId')
    @subscriptionModel.set('_id', @model.get('subscriptionModelId'))

  @setChannelsView()
  @model.on "updatedWhitelist", =>
    @setChannelsView()
    @renderChannelsView()

v.set 'setChannelsView', ()->
  @youtubeChannelsView = new WhitelistChannelsView
    model: @model
    collection: @model.youtubeCollection
    subscription: @subscriptionModel

  @twitchChannelsView = new WhitelistChannelsView
    model: @model
    collection: @model.twitchCollection
    subscription: @subscriptionModel

  @channels =
    "yt-channels": @youtubeChannelsView
    "twitch-channels": @twitchChannelsView

v.set "getSubscriptionModel", (next)->
  return next() unless @subscriptionModel.get('_id')

  @subscriptionModel.fetch
    success: next

v.set "render", ->
  @getSubscriptionModel ()=>
    @renderer.locals.inactive = @model.requiresSubscription(@subscriptionModel)
    @renderer.render()
    @renderChannelsView()

v.set 'renderChannelsView', ->
  ytEl = @el.querySelector("td.yt-channels")
  twchEl = @el.querySelector("td.twitch-channels")

  ytEl.innerHTML = ""
  twchEl.innerHTML = ""

  ytEl.appendChild(@youtubeChannelsView.el)
  twchEl.appendChild(@twitchChannelsView.el)

  @youtubeChannelsView.render() if @youtubeChannelsView
  @twitchChannelsView.render() if @twitchChannelsView

module.exports = v.make()
