eurl    = require('end-point').url
request = require("superagent")
view    = require("view-plugin")

sel =
  password: "[role='password']"
  confirm: "[role='confirm']"
  code: "[role='verification-code']"
  btn:
    update: "[role='update']"
    signin: "[role='signin']"

onClickUpdate = (e)->
  @n.evaluateClass("working", true)
  request
  .post(eurl("/password/reset"))
  .withCredentials()
  .send
    code: @code
    password: @n.getValue(sel.password)
  .end ( err, res ) =>
    @n.evaluateClass("working", false)
    return @displayError(err.message) if err
    if res.status isnt 200
      return @displayError(res.body?.error or "An error occured.")
    @displaySuccess(@i18.strings.forgotPassword.updateSuccess)

onKeyUpPassword = (e)->
  if @keyTimer?
    clearTimeout(@keyTimer)
  @keyTimer = setTimeout =>
    @checkPasswords()
  , 500

ForgotPasswordView = v = bQuery.view()

v.use view
  className: "forgot-password-view sign-up-view"
  template: require("./template")

v.on "keyup #{sel.password}", onKeyUpPassword
v.on "keyup #{sel.confirm}", onKeyUpPassword
v.on "click #{sel.btn.update}", onClickUpdate

v.set "render", ->
  @renderer.render()
  @setCode(@code or "")

v.set "open", (code="")->
  @setCode(code)

v.set "setCode", ( @code )->

v.set "displayForm", ( form )->
  @n.evaluateClass(".setup", "hide", form isnt "update")
  @n.evaluateClass(sel.btn.signin, "hide", form isnt "signin")

v.set "displayMessage", ( type, message )->
  selector = ".msg.bg-#{type}"
  @n.evaluateClass(selector, "hide", !message)
  @n.setText(selector, message)

v.set "displayError", ( error )->
  @displayMessage("success")
  @displayMessage("error", error)
  @displayForm("update")

v.set "displaySuccess", ( message )->
  @displayMessage("error")
  @displayMessage("success", message)
  @displayForm("signin")

v.set "checkPasswords", ->
  password = @n.getValue(sel.password)
  confirm = @n.getValue(sel.confirm)
  invalid = confirm and password and password != confirm
  @n.evaluateClass(sel.password, "error", invalid)
  @n.evaluateClass(sel.confirm, "error", invalid)
  @displayError(if invalid then @i18.strings.forgotPassword.passwordMismatch else "")

module.exports = v.make()
