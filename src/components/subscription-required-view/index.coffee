TemplateRenderer = require("template-renderer")

class SubscriptionRequiredView extends Backbone.View

  className: "subscription-required-view"

  initialize: ( opts={} ) ->
    @renderer = new TemplateRenderer
      view: @
      template: require("./template")

  render: ->
    @renderer.render()

module.exports = SubscriptionRequiredView
