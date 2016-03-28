v = bQuery.view()
View = require("view-plugin")
WhitelistChannelView = require("whitelist-channel-view")
Promise = require('bluebird')

v.use View
  className: "channels-view"
  template: require("./template")

v.init (opts={})->
  @views = []
  { @subscription } = opts

v.set "render", ->
  @renderer.render()

v.collection
  append: yes
  tag: "[role='list']"
  createView: (m)->
    newView = new WhitelistChannelView
      model: m
      user: @model
      collection: @collection
      subscription: @subscription

    @views.push newView
    newView

v.set 'whitelisted', ->
  pros = _.map @views, (view)-> view.whitelisted()
  return Promise.all(pros)

module.exports = v.make()
