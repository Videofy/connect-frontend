LabelSettingsView          = require("label-settings-view")
PublisherCollection        = require('publisher-collection')
PublishersView             = require('publishers-view')
SubscriptionPlanCollection = require("subscription-plans-collection")
SubscriptionPlansView      = require("subscription-plans-view")
TabView                    = require("tab-view")
View                       = require("view-plugin")

LabelPageView = v = bQuery.view()

v.use View
  className: "label-page-view"
  template: require("./template")

v.init (opts={})->
  pubopts = _.clone(opts)
  pubopts.collection = new PublisherCollection null,
    by:
      key: 'label'
      value: @model.id

  @tabs = new TabView
  tabSections =
    settings:
      title: "Settings"
      view: new LabelSettingsView(opts)
    publishers:
      title: "Publishers"
      view: new PublishersView(pubopts)

  if @permissions.canAccess('subscriptionPlan.create')
    plopts = _.clone(opts)
    plopts.collection = new SubscriptionPlanCollection null,
      by:
        key: 'labelId'
        value: @model.id
    tabSections.plans =
        title: "Plans"
        view: new SubscriptionPlansView(plopts)

  @tabs.set tabSections
  @tabs.active = "settings"

v.set "render", ->
  @renderer.render()
  @tabs.render()
  @el.appendChild(@tabs.el)

module.exports = v.make()
