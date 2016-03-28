Enabler = require("enabler")
TemplateRenderer = require("template-renderer")
StripePaymentView = require("stripe-payment-view")
PaypalPaymentView = require("paypal-payment-view")

class SubscriptionPaymentView extends Backbone.View
  className: "subscription-payment-view"

  initialize: ( opts={} ) ->
    @n = new Enabler(@el)
    @renderer = new TemplateRenderer
      view: @
      template: require("./template")
    @stripePaymentView = new StripePaymentView(opts)
    @paypalPaymentView = new PaypalPaymentView(opts)
    @sel =
      mysub: ".my-subscription-name"

  render: ->
    @renderer.render()
    @stripePaymentView.render()
    @el.appendChild(@stripePaymentView.el)
    @paypalPaymentView.render()
    @el.appendChild(@paypalPaymentView.el)

  getCard: (done)->
    @stripePaymentView.getStripeCard(done)

module.exports = SubscriptionPaymentView
