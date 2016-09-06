TemplateRenderer = require("template-renderer")

class SubscriptionRequiredView extends Backbone.View

  className: "subscription-required-view"

  initialize: ( opts={} ) ->
    @renderer = new TemplateRenderer
      view: @
      template: require("./template")
    @el.addEventListener "click", =>
      @el.classList.toggle("hide")
  render: ->
    @renderer.render()

module.exports = SubscriptionRequiredView
