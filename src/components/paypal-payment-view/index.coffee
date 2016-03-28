Enabler          = require("enabler")
eurl             = require('end-point').url
TemplateRenderer = require("template-renderer")
request          = require("superagent")
subPlan          = require("subscription-plan")
parse            = require('parse')

class PaypalPaymentView extends Backbone.View

  className: 'paypal-payment-view'

  events:
    "click [role='change-paypal-profile']": "changePaypalProfile"

  initialize: ( opts={} ) ->
    @n = new Enabler(@el)
    @user = @model
    @user.on 'change', @updateView.bind(@)
    @renderer = new TemplateRenderer
      view: @
      template: require("./template")
    @sel =
      error: "p.msg.bg-error"
      paypalInfo: ".paypal-info"
      paypalEmail: ".paypal-email"

  changePaypalProfile: (e)->
    planId = @user.get("subscriptionPlan")

    subPlan.getPlan { planId: planId }, (err, plan)->
      request
      .post(eurl("/subscription/paypal/sign-up/licensee"))
      .withCredentials()
      .send({ plan: plan })
      .end (err, res) =>
        err = parse.superagent(err, res)
        return alert(err) if err
        if res.status isnt 201
          return alert(res.body.error or "Unable to complete transaction. Please try again later.")
        window.location.replace(res.body)

  render: ->
    @renderer.render()
    @updateView()

  updateView: ->
    return unless @el.firstChild
    paypalSubscriber = if @user.get('subscriptionPaymentType') is 'paypal' then true else false
    paypalEmail = @user.get 'subscriptionPaymentEmail'
    @n.setText(@sel.paypalEmail, paypalEmail) if paypalEmail
    @n.evaluateClass(@sel.paypalInfo, "hide", !paypalSubscriber or !paypalEmail)
    @n.evaluateClass(@sel.error, "hide", !(paypalSubscriber and !paypalEmail))


module.exports = PaypalPaymentView
