Enabler          = require("enabler")
eurl             = require('end-point').url
request          = require("superagent")
TemplateRenderer = require("template-renderer")
subPlan          = require("subscription-plan")
parse            = require('parse')

class StripePaymentView extends Backbone.View

  className: "stripe-payment-view"

  events:
    "click [role='change-card']": "showStripeForm"

  initialize: ( opts={} ) ->
    @n = new Enabler(@el)
    { @user } = opts
    @card = null

    @renderer = new TemplateRenderer
      view: @
      template: require("./template")

    @sel =
      card:
        section: ".creditcard"
        missing: ".stripe-card-missing"
        number: ".creditcard label[role='number']"
        type: ".creditcard label[role='type']"
        date: ".creditcard label[role='expiry']"
      error: "p.msg.bg-error"
      email: "label[role='email']"

  render: ->
    @renderer.render()
    @updateStripePayment()

  displayError: ( error ) ->
    @n.evaluateClass(@sel.error, "hide", !error)
    @n.setText(@sel.error, error)

  updateStripePayment: ()->
    @getStripeCard (err, card)=>
      validCard = if (card? and card.last4) then true else false
      @n.evaluateClass(@sel.card.section, "hide", !validCard)
      @n.evaluateClass(@sel.card.missing, "hide", validCard)
      email = @model.get('subscriptionPaymentEmail')

      if validCard
        @card = card
        @n.setText(@sel.card.type, card.brand)
        @n.setText(@sel.card.number, "**** **** **** #{card.last4}")
        @n.setText(@sel.card.date, "#{card.exp_month} / #{card.exp_year}")

      @n.setText(@sel.email, email) if email

  getStripeCard: (done)->
    return done(null, @card) if @card
    request
      .get(eurl("/subscription/stripe-card/#{@model.id}"))
      .withCredentials()
      .send()
      .end (err, res)=>
        if err
          err = parse.superagent(err, res)
          @displayError(err)
          return done(err, null)

        return done(err, res.body)

  showStripeForm: (e)->
    planId = @model.get("subscriptionPlan")
    unless planId?
      channelNum = 2
      period = 1

    subPlan.getPlan { planId: planId, channelNum: channelNum, period: period }, (err, plan)=>
      return alert(err) if err

      handler = StripeCheckout.configure
        key: plan.key
        image: plan.image
        token: (token)=> @updateStripeCard(token, plan)

      handler.open
        name: "Change Payment Method",
        description: ""

  updateStripeCard: (token, plan)->
    request
      .put(eurl("/subscription/stripe-card/#{@model.id}"))
      .withCredentials()
      .send({ stripeToken: token, plan: plan })
      .end (err, res)=>
        return @displayError(err) if err
        if res.status isnt 200
          return @displayError(res.body?.error or "An unknown error occured.")
        @updateStripePayment()
        @user.fetch()

module.exports = StripePaymentView
