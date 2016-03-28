SubscriptionPaymentView  = require('subscription-payment-view')
UpdateSubscriptionView   = require("update-subscription-view")
SubscriptionReferralView = require("subscription-referral-view")
ReferralCollection       = require("referral-collection")
UserModel                = require("user-model")
View                     = require("view-plugin")
subPlan                  = require("subscription-plan")
request                  = require("superagent")
parse                    = require('parse')

sel =
  cancel: "[role='cancel-plan-btn']"
  renewSub: "[role='renew-sub']"
  renewStripe: "[role='renew-stripe']"
  renewPaypal: "[role='renew-paypal']"
  renewText1: "[role='renew-text-1']"
  renewText2: "[role='renew-text-2']"
  status: "[role='status']"
  statusText: "[role='status-text']"
  icon:
    ok: "i.fa-check-circle"
    no: "i.fa-exclamation-circle"
  msg:
    info: "p.ss.msg.bg-info"
    error: "p.ss.msg.bg-error"
  manageSubscription: ".manage-subscription-view"
  managePayment: "[role='manage-payment']"
  newsub: ".new-subscription-view"
  typeChange: ".type-select"
  editPaymentBtn: "[role='edit-payment-btn']"
  editPlanBtn: "[role='edit-plan-btn']"
  updatePaymentSec: ".update-payment-method"
  updateSubscriptionSec: ".update-subscription"
  planName: ".plan-name"
  planDetail: ".plan-detail"
  planPrice: ".plan-price"
  dealPrice: ".deal-price"
  nextPayment: ".next-payment"
  paymentMethod: "[role='payment-method']"

cancelText =
  licensee: " - Channels will be removed from whitelist at end of period."
  golden: " - Access will be revoked at end of period."

paymentName =
  "stripe": "Stripe"
  "paypal": "PayPal"

v = bQuery.view()

v.use View
  className: "commercial-subscription-view"
  template: require("./template")

v.on "click #{sel.renewStripe}", 'addSubscription'
v.on "click #{sel.renewPaypal}", 'addSubscription'
v.on "click #{sel.cancel}", "onClickCancel"
v.on "click #{sel.editPlanBtn}", "onClickEditPlan"
v.on "click #{sel.editPaymentBtn}", "onClickEditPayment"
v.on "change .type-select", 'typeChange'

v.init (opts={})->
  { @permissions, @user } = opts
  @paymentView = new SubscriptionPaymentView(opts)
  @updateSubscriptionView = new UpdateSubscriptionView(opts)
  @updatePaymentHide = true
  @updatePlanHide = true

  referrals = new ReferralCollection null,
    by:
      key: 'referrerId'
      value: @user.id

  @referralView = new SubscriptionReferralView
    collection: referrals
    evs: @evs
    i18: @i18
    permissions: @permissions
    user: @user

  @listenTo @user, 'change', =>
    subPlan.getPlansByUserTypes { userTypes: @user.get('type') }, (err, plans)=>
      @plans = plans
      @render()

v.set 'onClickEditPayment', ->
  @updatePaymentHide = !@updatePaymentHide
  @n.evaluateClass(sel.updatePaymentSec, "hide", @updatePaymentHide)

v.set 'onClickEditPlan', ->
  @updatePlanHide = !@updatePlanHide
  @n.evaluateClass(sel.updateSubscriptionSec, "hide", @updatePlanHide)

v.set 'renderReferralView', ->
  @referralView.render()
  @el.appendChild(@referralView.el)

v.set "getPaymentDate", ->
  periodEndFormated = @model.getAsFormatedDate("subscriptionPeriodEnd")
  status = @getSubscriptionStatus()
  if status is 'active'
    return "Next payment on #{periodEndFormated} "
  else
    return "Subscription ends on #{periodEndFormated} "

v.set "getCredit", ->
  newCredit = if @model.get('subscriptionCreditNew') then @model.get('subscriptionCreditNew') else  0
  appliedCredit = if @model.get 'subscriptionCreditApplied' then @model.get 'subscriptionCreditApplied' else 0
  return newCredit + appliedCredit

v.set "render", ->
  @renderer.locals.mode = "loading"
  @renderer.render()
  @model.fetch
    success: (sub)=>
      @syncSubscription()
      userTypes = @user.get('type') or ['golden', 'subscriber']
      subPlan.getPlansByUserTypes { userTypes: userTypes }, (err, plans)=>
        @plans = plans
        @plan = @getPlan()
        subscriber = @user.get("subscriber")
        subStatus = @getSubscriptionStatus()
        goldUser = if "golden" in userTypes then true else false
        cancelNote = if @user.isOfTypes("golden") then cancelText["golden"] else cancelText["licensee"]

        @renderer.locals.mode = subStatus
        @renderer.locals.credit = "$#{@getCredit()/100}"
        @renderer.locals.planName = @getPlanName()
        @renderer.locals.planPrice = @plan.description if @plan
        @renderer.locals.dealPrice = @getDealPrice()
        @renderer.locals.paymentDate = @getPaymentDate()
        @renderer.locals.referral = @permissions.user.referral
        @renderer.locals.goldUser = goldUser
        @renderer.locals.cancelNote = cancelNote
        @renderer.locals.renewText = " for #{@plan?.description}"
        @renderer.render()

        if subStatus is 'active'
          @setPaymentMethod()
          @paymentView.render()
          @n.getEl(sel.updatePaymentSec).appendChild(@paymentView.el)
          @updateSubscriptionView.render()
          @n.getEl(sel.updateSubscriptionSec).appendChild(@updateSubscriptionView.el)
          @updateSubscriptionView.on 'cancelSubscription', ()=>
            @onClickCancel()

          @n.evaluateClass(sel.updatePaymentSec, "hide", true)
          @n.evaluateClass(sel.updateSubscriptionSec, "hide", true)
          @renderReferralView() if @permissions.user.referral
     error: (model, res)=>
       @renderer.locals.mode = 'error'
       @renderer.locals.error = 'An error occured.'
       @renderer.render()

v.set 'typeChange', (e)->
  gold = if e.target.value is 'gold' then true else false
  userTypes = if gold then ["subscriber", "golden"] else ["subscriber", "licensee"]
  subPlan.getPlansByUserTypes { userTypes: userTypes }, (err, plans)=>
    @plans = plans
    plan = @getBasePlan()
    @n.setText(sel.renewText2, " for #{plan.description}.")

v.set "displayError", (error)->
  @n.evaluateClass(sel.msg.error, "hide", !error)
  @n.setText(sel.msg.error, error)

v.set "respond", (err, res ,next)->
  err = parse.superagent(err, res)
  return @displayError(err) if err
  unless res.status is 200 or res.status is 201
    return @displayError(res.body?.message or res.body?.error or "An unknown error occured.")
  @displayError()
  @user.fetch
    success: ()=> next?()

v.set "addPaypalSubscription", (plan)->
  request
  .post("/subscription/paypal/sign-up/licensee")
  .send
    plan: plan
  .end (err, res) =>
    @n.evaluateClass("waiting", false)
    return alert(err) if err

    if res.status isnt 201
      return alert(res.body?.error or "Unable to complete transaction. Please try again later.")

    window.location.replace(res.body)

v.set "charge", (token, plan)->
  request
  .post("/subscription/stripe/sign-up/licensee")
  .send
    returnUrl: "#{location.protocol}//#{location.host}/#sign-up/:code"
    plan: plan
    stripeToken: token
  .end (err, res)=>
    @respond(err, res)
    @evs.trigger("subscription:charged-stripe")

v.set "cancel", ->
  request
  .post("/subscription/cancel/#{@model.id}")
  .end (err, res)=>
    @respond err, res, =>
      @router.navigate("/subscription/survey", trigger: true)

v.set "syncSubscription", ->
  request
  .get("/user/sync-subscription/#{@user.id}")
  .end (err, res)=>
    if res.status isnt 200
      return @displayError(res?.body?.error or "An error occured.")
    @respond.bind(@)

v.set 'getPlanName', ->
  status = @getSubscriptionStatus()
  if status is 'inactive'
    planName = "Subscription Inactive"
  else
    planName = @displayPlanName(@plan)

  return planName

v.set 'getSubscriptionStatus', ->
  active = !@user.requiresSubscription(@model)
  canceling = @model.get('subscriptionCanceling') or false

  if !active or !@user.get("subscriber")
    return 'inactive'
  else if canceling
    return 'canceling'
  else
    return 'active'

v.set "setPaymentMethod", ()->
  method = @model.get('subscriptionPaymentType')
  if method is 'stripe'
    @paymentView.getCard (err, card)=>
      validCard = if (card? and card.last4) then true else false
      if !validCard
        paymentInfo = "Error on get payment info, plese try again later."
      else
        paymentInfo = "#{card.brand} : **** **** **** #{card.last4}"
      @n.setText(sel.paymentMethod, paymentInfo)
  else
    paymentInfo = @model.get('subscriptionPaymentType')
    @n.setText(sel.paymentMethod, paymentName[paymentInfo])

v.set "displayPlanName", (plan)->
  type = if @user.isOfTypes("golden") then "Gold" else "Licensee"
  channel = if @user.isOfTypes("golden") then "" else "#{plan.channelNum} channels"

  if plan.period > 1
    duration = "#{plan.period} Months"
  else
    duration = "#{plan.period} Month"

  return "Monstercat #{type} Subscription #{channel} #{duration} "

v.set 'getDealPrice', ->
  curAmount = @model.get('subscriptionCurrentAmount')
  discounted = curAmount? and (curAmount < @plan.amount)
  return "" unless discounted

  disAmount = curAmount/100
  discountTag = if disAmount <= 0 then " Free!" else " $#{disAmount}/MONTH"
  return discountTag

v.set 'getStatusText', ->
  active = !@user.requiresSubscription(@model)
  canceling = @model.get('subscriptionCanceling') or false
  if active and not canceling
    return "Active"
  else if canceling
    return if @user.isOfTypes("golden") then cancelText["golden"] else cancelText["licensee"]
  else
    return "Inactive"

v.set 'getPlan', ()->
  planId = @model.get("subscriptionPlan")

  if @model.get("subscriptionPlanDetails") and @model.get("subscriptionPlanDetails").planId
    result = @model.get("subscriptionPlanDetails")
  else if planId
    result = _.find @plans, (plan)-> plan.planId is planId
  else
    result = @getBasePlan()

  return result

v.set 'getBasePlan', ->
  result = _.find @plans, (plan)->
    return "#{plan.channelNum}" is '2' and "#{plan.period}" is '1'

  return result

v.set "addSubscription", (e)->
  role = e.target.getAttribute('role')
  type = if role is 'renew-stripe' then 'stripe' else 'paypal'
  myPlan = @getPlan()

  validCard = if (card? and card.last4) then true else false

  if role is 'renew-stripe'
    @showForm(myPlan)
  else
    @addPaypalSubscription(myPlan)

v.set "showForm", (plan)->
  stripeHandler = StripeCheckout.configure
    key: plan.key
    image: plan.image or '/img/monstercat-square.png'
    token: (token)=> @charge(token, plan)

  stripeHandler.open
    name: plan.name
    description: plan.description

v.set "onClickCancel", (e)->
  if confirm("Are you sure you want to cancel your subscription?")
    @cancel()

module.exports = v.make()
