eurl             = require('end-point').url
Enabler          = require("enabler")
request          = require("superagent")
TemplateRenderer = require("template-renderer")

class VerifyView extends Backbone.View

  initialize: ( opts={} ) ->
    { @router } = opts
    @n = new Enabler(@el)
    @renderer = new TemplateRenderer
      view: @
      template: require("./template")
    @sel =
      realName: "[role='real-name']"
      newPassword: "[role='new-password']"
      confirmPassword: "[role='confirm']"
      verify: "[role='verify']"
      return: "[role='return']"

  render: ->
    @renderer.render()
    keyup = @onNewPasswordKeyUp.bind(@)
    @n.bind(@sel.newPassword, "keyup", keyup)
    @n.bind(@sel.confirmPassword, "keyup", keyup)
    @n.bind(@sel.realName, "keyup", @onRealNameKeyUp.bind(@))
    @n.bind(@sel.verify, "click", @onClickVerify.bind(@))
    @n.bind(@sel.return, "click", @onClickReturn.bind(@))

  open: (code="")->
    @setCode(code)

  setCode: ( code ) ->
    @displayForm("loader")
    request
      .get(eurl("/invite/info/#{code}"))
      .withCredentials()
      .end ( err, res ) =>
        @displayForm("return")
        if err
          return @displayError(err.message or "An request error occured.")

        if res.status isnt 200
          return @displayError(res.body?.error or "Could not get verification information.")

        @code = code
        @displayForm("new-account")

  verify: ->
    prevForm = @form
    @displayForm("loader")

    request
      .post(eurl("/invite/complete"))
      .withCredentials()
      .send
        code: @code
        realName: @n.getValue(@sel.realName)
        password: @n.getValue(@sel.newPassword)
      .end ( err, res ) =>
        if err
          @displayForm(prevForm)
          return @displayError(err.message or "An request error occured.")

        if res.status isnt 200
          @displayForm(prevForm)
          return @displayError(res.body?.error or "Could not verify user.")

        @displayForm("")
        @displaySuccess("User succesfully verified.")

  displayForm: ( type ) ->
    @form = type
    @n.evaluateClass(".loader", "hide", type isnt "loader")
    @n.evaluateClass(".setup", "hide", !(type == "new-account"))
    @n.evaluateClass("[role='return']", "hide", type isnt "return")

  displayMessage: ( type, message ) ->
    sel = ".msg.bg-#{type}"
    @n.evaluateClass(sel, "hide", !message)
    @n.setText(sel, message)

  displaySuccess: ( message ) ->
    @displayMessage("error")
    @displayMessage("success", message)
    @displayForm("return")

  displayError: ( error ) ->
    @displayMessage("error", error)

  onFormFilled: ->
    @n.evaluateDisabled(@sel.verify, !@isPasswordsValid() or !@isRealNameValid())

  updatePasswordDisplay: ->
    invalid = !@isPasswordsValid(true)
    @n.evaluateClass(@sel.newPassword, "error", invalid)
    @n.evaluateClass(@sel.confirmPassword, "error", invalid)
    @onFormFilled()

  delay: ( time, func ) ->
    if @keyupTimer
      clearTimeout(@keyupTimer)

    @keyupTimer = setTimeout =>
      func()
    , time

  isRealNameValid: ->
    return true if @n.getValue(@sel.realName)

  onRealNameKeyUp: (e) ->
    @delay(200, @onFormFilled.bind(@))

  isPasswordsValid: ( allowEmpty )->
    pass = @n.getValue(@sel.newPassword)
    confirm = @n.getValue(@sel.confirmPassword)

    return true if allowEmpty and (!pass or !confirm)

    pass and confirm and pass is confirm

  onNewPasswordKeyUp: ( e ) ->
    @delay(200, @updatePasswordDisplay.bind(@))

    if e.keyCode is 13 and @isPasswordsValid()
      @verify()

  onClickVerify: ( e ) ->
    @verify()

  onClickReturn: ( e ) ->
    @router.navigate("/", trigger: true)

module.exports = VerifyView
