PresenterView     = require("presenter-view")
parse             = require('parse')
request           = require("superagent")
scrollTo          = require("scroller")
SigninView        = require("signin-view")
subPlan           = require("subscription-plan")
View              = require("view-plugin")
eurl              = require('end-point').url

sel =
  goldEmail: "[role='gold-email']"
  licenseEmail: "[role='license-email']"
  goldCode: "[role='gold-referral-code']"
  licenseCode: "[role='license-referral-code']"
  goldPrice: "[role='gold-price']"

goldAccess = ["golden", "mixcomp"]

capitalize = (str)->
  return undefined if !str
  return str.charAt(0).toUpperCase() + str.slice(1)

step = ->
  height = document.body.clientHeight
  for el in @banners
    rect = el.getBoundingClientRect()
    continue if rect.top + rect.height < 0 or rect.top > height
    y = (rect.top + rect.height * 0.5) - (height * 0.5)
    percentY = 50 + y / height * 100
    percentX = if el.classList.contains("banner-right") then 100 else 0
    el.style.backgroundPosition = "#{percentX}% #{percentY}%"

  window.requestAnimationFrame(@step)

referralCodeOpen = (types)->
  openTypes = ["golden","mixcomp","licensee"]
  types = types or []
  return _.intersection(openTypes, types).length > 0

WelcomeView = v = bQuery.view()

v.use View
  className: "welcome-view"
  template: require("./template")

v.ons
  "click [role='stripe']": "onClickStripe"
  "click [role='paypal']": "onClickPayPal"
  "click [role='signin']": "onClickSignIn"
  "click [role='go-details']": "onClickGoDetails"
  "click [role='go-gold']": "onClickGoGold"
  "click [role='go-license']": "onClickGoLicense"
  "click [role='go-pricing']": "onClickGoPricing"
  "click [role='scroll-up']": "onClickScrollUp"
  "click [role='show-gold-form']": "onClickShowGoldForm"
  "click [role='show-license-form']": "onClickShowLicenseForm"
  "click [role='mix-signUp']": "onClickSignUp"
  "change [role='channels']": "onChangeChannel"

v.init (opts={})->
  { @session, @router } = opts
  @presenter = new PresenterView
  @presenter.el.classList.add("signin", "flexi")
  @planOptions =
    channels: {}



v.set "open", (@url)->
  @needle = @url.split('/')[0]
  @code = @url.split('/')[1]

  if @needle is "sign-in"
    return @openSignin()

  if @needle is 'referral'
    @getCode @code, (err, code)=>
      return alert("An error occurred. Please visit later.") if err
      return alert("Invalid referral code #{@code} is provided!") unless code
      @userType = code.userType.split(',')
      @codeDetails = code
      @gold = @isGold(@userType)
      @n.evaluateClass(@el, "goldie", @gold)
      @render()
  else
    @userType = @getTypeFromNeedle(@needle)
    @gold = @isGold(@userType)
    @n.evaluateClass(@el, "goldie", @gold)
    @render()

v.set 'isGold', (userType)->
  goldTypes = ["golden", "mixcomp" ]
  userType = userType or []
  return _.intersection(goldTypes, userType).length > 0

v.set 'getTypeFromNeedle', (needle)->
  typeMap =
    'gold': ["golden", "subscriber"],
    'license': ["licensee", "subscriber"]

  return typeMap[needle]

v.set 'getCode', (code, done)->
  request
  .get "/subscription/referral-code-detail"
  .query
    referralCode: code
  .end ( err, res ) =>
    err = parse.superagent(err, res)
    return done(err, res.body.code)

v.set "render", ->
  @renderPlans()
  @presenter.attach()
  @banners = @el.querySelectorAll(".banner")
  @step = step.bind(@)
  window.requestAnimationFrame and window.requestAnimationFrame(@step)
  window.document.title = @getTitle(@userType)

  if @needle is 'returned'
    return alert("There was a problem with your payment. Either you do not have enough money on your account or your country
                  is not supported. For further inquiries please contract us at monstercatlicensing@gmail.com.")

v.set 'getTitle', (userType)->
  userType = userType or []
  if "golden" in userType
    return "Monstercat Gold Beta"
  else if "licensee" in userType
    return "Monstercat License Beta"
  else
    return "Monstercat Connect Beta"

v.set "getMode", (userType)->
  userType = userType or []

  if "golden" in userType
    return "golden"
  else if "licensee" in userType
    return "licensee"
  else if "mixcomp" in userType
    return "mixcomp"
  else
    return "all"

v.set 'prefillCode', ->
  el = if @gold then sel.goldCode else sel.licenseCode
  @n.setText(el, @code)

v.set "renderPlans", ->
  subPlan.getPlan { userTypes: @userType, active: true, multiple: true }, (err, plans)=>
    return alert(err) if err
    @options = {}
    @plans = plans

    plans = _.sortBy plans, (plan)-> return plan.channelNum

    if plans and plans.length > 0
      @options.channels = plans[0].channelNum
      _.each plans, (plan)=>
        unless @planOptions.channels["#{plan.channelNum}"]
          @planOptions.channels["#{plan.channelNum}"] = plan.channelNum

    @renderer.locals.options = @planOptions
    @renderer.locals.mode = @getMode(@userType)
    @renderer.locals.goldTitle = @renderer.locals.mode in goldAccess

    if @codeDetails and @codeDetails.trialDates
      @renderer.locals.trialPeriod = "#{@codeDetails.trialDates} days"

    @renderer.locals.referralCodeOpen = referralCodeOpen

    @renderer.render()
    @prefillCode() if @code and referralCodeOpen(@userType)

v.set "openSignin", ->
  view = new SigninView
    session: @session
    router: @router
    i18: @i18
  view.render()
  @presenter.open(view)
  @presenter.once "close:end", =>
    @router.navigate("")
  view.focus(100)

v.set "onClickSignIn", ->
  @router.navigate("sign-in", trigger: true)

v.set "goTo", (y)->
  contents = @n.getEl(".contents")
  scrollTo(contents, y, 200)

v.set "onClickGoDetails", (e)->
  y = @n.getEl(".details").offsetTop -
    @n.getEl("nav").getBoundingClientRect().height
  @goTo(y)

v.set "onClickGoGold", (e)->
  y = @n.getEl(".gold-details").offsetTop -
    @n.getEl("nav").getBoundingClientRect().height
  @goTo(y)

v.set "onClickGoLicense", (e)->
  y = @n.getEl(".license-details").offsetTop -
    @n.getEl("nav").getBoundingClientRect().height
  @goTo(y)

v.set "onClickGoPricing", (e)->
  y = @n.getEl(".pricing").offsetTop -
    @n.getEl("nav").getBoundingClientRect().height
  @goTo(y)

v.set "onClickScrollUp", (e)->
  @goTo(0)

v.set "resetForms", ->
  @n.getEl("[role='gold-form']")?.classList.add("hide")
  @n.getEl("[role='license-form']")?.classList.add("hide")
  @n.getEl("[role='show-gold-form-btn']")?.classList.remove("hide")
  @n.getEl("[role='show-license-form-btn']")?.classList.remove("hide")

v.set "displayForm", (form)->
  @n.evaluateClass(form, "hide", false)

  y = form.offsetTop - @n.getEl("nav").getBoundingClientRect().height
  scrollTo(@n.getEl(".contents"), y, 500)

v.set "getPlans", (done)->
  subPlan.getPlan
    userTypes: @userType,
    active: true,
    multiple: true
    (err, plans)=>
      return alert(err) if err
      return done(null, plans)

v.set "onClickShowGoldForm", (e)->
  @gold = true
  @userType = ['golden', 'subscriber']
  @getPlans (err, plans)=>
    @plans = plans
    @resetForms()
    @displayForm(@n.getEl("[role='gold-form']"))
    @n.evaluateClass(@n.getEl("[role='show-gold-form-btn']"), "hide", true)

v.set "onClickShowLicenseForm", (e)->
  @gold = false
  @userType = ['licensee', 'subscriber']
  @getPlans (err, plans)=>
    @plans = plans
    @resetForms()
    @displayForm(@n.getEl("[role='license-form']"))
    @n.evaluateClass(@n.getEl("[role='show-license-form-btn']"), "hide", true)

v.set "getEmail", ->
  email = if @gold then @n.getValue(sel.goldEmail) else @n.getValue(sel.licenseEmail)
  email = undefined if !/.+@.+\..+/.test(email)
  @n.evaluateClass((if @gold then sel.goldEmail else sel.licenseEmail), "error", !email)
  if email then email else alert("Please provide your email address.")

v.set "validateCode", (code, done)->
  request
  .post(eurl("/subscription/validate-referral-code"))
  .send
    referralCode: code
  .end (err, res)=>
    if err = parse.superagent(err, res)
      @n.evaluateClass("waiting", false)
      return done(err.message, false)
    else
      return done(null, res.body?.valid)

v.set "getReferralCode", (next)->
  return next(null, null) unless referralCodeOpen(@userType)
  code = if @gold then @n.getValue(sel.goldCode) else @n.getValue(sel.licenseCode)
  return next(null, code) unless code

  @validateCode code, (err, valid)->
    return next(err, code) if err
    return next("Invalid referrence code.") unless valid
    next(null, code)

v.set "getPaymentConfig", ->
  result = _.find @plans, (plan)=>
    { channels } = @options
    if plan.channelNum is channels
      return plan

  return alert("An error occurred while finding the payment configuration.") if !result
  return result

v.set "onClickSignUp", (e)->
  return if !userEmail = @getEmail()
  @getReferralCode (err, code)=>
    return alert(err) if err
    @n.evaluateClass("waiting", true)
    request
    .post(eurl("/subscription/mixcomp/sign-up"))
    .send
      returnUrl: "#{location.protocol}//#{location.host}/#sign-up/:code"
      userEmail: userEmail
      referralCode: code
    .end ( err, res ) =>
      if err = parse.superagent(err, res)
        @n.evaluateClass("waiting", false)
        return alert(err.message)
      @router.navigate("/sign-up/#{res.body.verify}", trigger: true)

v.set "onClickPayPal", (e)->
  return if !userEmail = @getEmail()
  @getReferralCode (err, code)=>
    return alert(err) if err
    @n.evaluateClass("waiting", true)
    plan = @getPaymentConfig()

    request
    .post(eurl("/subscription/paypal/sign-up/licensee"))
    .send
      plan: plan
      userEmail: userEmail
      referralCode: code
      approvedRedirectUrl: "#{window.location.origin}/#sign-up"
      cancelledRedirectUrl: "#{window.location.origin}/#returned"
    .end ( err, res ) =>
      if err = parse.superagent(err, res)
        @n.evaluateClass("waiting", false)
        return alert(err.message)

      window.location.replace(res.body)

v.set "onClickStripe", (e)->
  e.preventDefault()
  return if !@getEmail()
  @getReferralCode (err, code)=>
    return alert(err) if err

    @n.evaluateClass("waiting", true)
    plan = @getPaymentConfig()

    stripeHandler = StripeCheckout.configure
      key: plan.key
      image: plan.image
      token: (token)=> @onStripeToken(token, plan)

    stripeHandler.open
      name: plan.name
      description: plan.description
      closed: =>
        @n.evaluateClass("waiting", false) unless @sendingToken

v.set "onStripeToken", ( token, plan )->
  @n.evaluateClass("waiting", true)
  @sendingToken = true
  userEmail = @getEmail()
  @getReferralCode (err, code)=>
    return alert(err) if err

    request
    .post(eurl("/subscription/stripe/sign-up/licensee"))
    .send
      returnUrl: "#{location.protocol}//#{location.host}/#sign-up/:code"
      stripeToken: token
      plan: plan
      userEmail: userEmail
      referralCode: code
    .end ( err, res ) =>
      @sendingToken = false
      @n.evaluateClass("waiting", true)

      if err = parse.superagent(err, res)
        @n.evaluateClass("waiting", false)
        return alert(err.message)

      unless res.body.user
        @n.evaluateClass("waiting", false)
        return alert("An unexpected error occured. Please contact us at monstercatlicensing@gmail.com.")
 
      @router.navigate("/sign-up/#{res.body.user.verify}", trigger: true)

v.set "onChangeChannel", (e)->
  @options.channels = parseInt(e.currentTarget.value)
  @updatePlan()

v.set "updatePlan", (e)->
  plan = @getPaymentConfig()
  @n.setText("[role='price']", "#{plan.description}")

module.exports = v.make()
