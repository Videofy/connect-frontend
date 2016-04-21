eurl    = require('end-point').url
request = require("superagent")
view    = require("view-plugin")
wait    = require('wait')

saveCredentials = (email, password)->
  return if not store = window.localStorage
  try
    store.setItem("signinEmail", email)
  catch e
    # Do nothing...

retrieveCredentials = ->
  obj =
    email: ""
    password: ""

  if store = window.localStorage
    obj.email = store.getItem("signinEmail") or ""

  obj

onClickSignIn = ( e )->
  @signin()

onClickForgot = ( e )->
  @displayForm("forgot")

onClickSendReset = ( e )->
  @sendReset()

onClickBackToSignin = ( e )->
  @displayForm("signin")

onClickResendToken = ( e )->
  @clearMessage()
  @n.evaluateClass("[role='resend-token']", "active", true)

  resp = (err, res)=>
    @n.evaluateClass("[role='resend-token']", "active", false)
    if res.status isnt 200
      return @displayError(res?.body?.error or "An error occured.")
    return @displayMessage("token", res?.body?.message or 'Token resent.')

  @session.resendToken(resp)

onClickVerifyToken = ( e )->
  @clearMessage()
  @n.evaluateClass("[role='verify-token']", "active", true)

  resp = (err, res)=>
    @n.evaluateClass("[role='verify-token']", "active", false)

    if res.status isnt 200
      return @displayError(res?.body?.error or "An error occured.")
    @router.reload()

  @session.verifyToken @n.getValue("input[role='token']"), resp

onKeyUp = ( e )->
  return unless e.keyCode is 13

  if @form is "signin"
    @signin()
  else if @form is "forgot"
    @sendReset()

SigninView = v = bQuery.view()

v.use view
  className: "signin-view"
  template: require("./template")

v.ons
  "click [role='signin']": onClickSignIn
  "click [role='forgot-password']": onClickForgot
  "click [role='send-reset']": onClickSendReset
  "click [role='back-to-signin']": onClickBackToSignin
  "click [role='verify-token']": onClickVerifyToken
  "click [role='resend-token']": onClickResendToken
  "keyup [role='email']": onKeyUp
  "keyup [role='password']": onKeyUp

v.init (opts={})->
  { @session, @router } = opts
  @form = "signin"

v.set "render", ->
  @renderer.render()
  credits = retrieveCredentials()
  @n.setText("[role='email']", credits.email)
  @n.setText("[role='password']", credits.password)

v.set "displayForm", ( type )->
  @form = type
  @n.evaluateClass("[role='password']", "hide", type isnt "signin")
  @n.evaluateClass("[role='send-reset']", "hide", type isnt "forgot")
  @n.evaluateClass("[role='forgot-password']", "hide", type isnt "signin")
  @n.evaluateClass("[role='signin']", "hide", type isnt "signin")
  @n.evaluateClass("[role='back-to-signin']", "hide", type isnt "forgot")
  @n.evaluateClass("[role='notice-forgot']", "hide", type isnt "forgot")
  @n.evaluateClass("[role='token']", "hide", type isnt "two-factor")
  @n.evaluateClass("[role='verify-token']", "hide", type isnt "two-factor")
  @n.evaluateClass("[role='resend-token']", "hide", type isnt "two-factor")
  @n.evaluateClass("[role='email']", "hide", type is "two-factor")
  @n.evaluateClass("[role='notice-token']", "hide", type isnt "two-factor")
  @clearMessage()

v.set "clearMessage", ->
  @displayMessage("error")
  @displayMessage("success")
  @displayMessage("token")

v.set "displayMessage", ( type, message )->
  selector = "[role='notice-#{type}']"
  @n.evaluateClass(selector, "hide", !message)
  @n.setText(selector, message)

v.set "displayError", ( error )->
  @displayMessage("success")
  @displayMessage("token")
  @displayMessage("error", error)

v.set "displaySuccess", ( message )->
  @displayMessage("error")
  @displayMessage("token")
  @displayMessage("success", message)

v.set "focus", (delay=16)->
  # iOS does not respect focus. Touch becomes messed up if called, probably due to flex display
  return if navigator.userAgent.match(/(iPad|iPhone|iPod)/g)
  setTimeout =>
    @n.getEl("[role='email']").focus()
  , delay

v.set "signin", ->
  email = @n.getValue("input[role='email']")
  password = @n.getValue("input[role='password']")
  @n.evaluateClass("[role='signin']", "active", true)

  resp = (err, res)->
    @n.evaluateClass("[role='signin']", "active", false)
    # 209 response, need two-factor token
    if res?.status is 209
      @displayForm("two-factor")
      return @displayMessage("token", res?.body?.message or @i18.strings.signin.twoFactorMsg)

    return @displayError(err.message) if err

    saveCredentials(email, password)
    @router.reload()

  @session.authenticate email, password, wait(750, @, resp)

v.set "sendReset", ->
  @clearMessage()
  @n.evaluateClass("[role='send-reset']", "active", true)

  resp = (err, res)->
    @n.evaluateClass("[role='send-reset']", "active", false)
    return @displayError(err.message) if err
    if res.status isnt 200
      return @displayError(res?.body?.error or "An error occured.")
    @displaySuccess(@i18.strings.signin.sentResetMsg)

  request
  .post(eurl("/password/send-verification"))
  .send
    email: @n.getValue("input[role='email']")
    returnUrl: "#{location.protocol}//#{location.host}/#forgot-password/:code"
  .end wait(750, @, resp)

module.exports = v.make()
