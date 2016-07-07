countries               = require("countries")
InputListView           = require("input-list-view")
parse                   = require("parse")
passwordToggle          = require("password-toggle-plugin")
UserShopInfoView        = require('user-shop-info-view')
UserShopInfoModel       = require('user-shop-info-model')
UserWhitelistCollection = require("user-whitelist-collection")
UserWhitelistView       = require("user-whitelist-view")
view                    = require("view-plugin")
wait                    = require("wait")
request                 = require('superagent')
callingCodes            = require('country-calling-codes')

sel =
  disable: '[role="disable-two-factor"]'
  status: '[role="two-factor-status"]'
  submit: '[role="submit-two-factor"]'
  country: '[role="country-code"]'
  countryCodePreview: '[role="country-code-preview"]'
  number: '[role="phone-number"]'
  show: '[role="show-two-factor"]'

onSubmitTwoFactor = (e)->
  number = @n.getEl(sel.number)?.value
  countryCode = @n.getEl(sel.country)?.value
  @n.evaluateClass(sel.submit, "active", yes)
  @model.setTwoFactor number, countryCode, (err)=>
    @n.evaluateClass(sel.submit, "active", no)
    return @toast(err.message, "error") if err
    @toast("Two Factor settings updated.")
    @n.getEl(sel.status)?.textContent = @i18.strings.twoFactor.enabled
    @n.getEl("#{sel.submit} > span")?.textContent = "Update"
    @n.evaluateClass(sel.disable, "hide", no)

onDisableTwoFactor = (e)->
  @n.evaluateClass(sel.disable, "active", yes)
  @model.disableTwoFactor (err)=>
    @n.evaluateClass(sel.disable, "active", no)
    return @toast(err.message, "error") if err
    @toast("Two Factor settings updated.")
    @n.getEl(sel.status)?.textContent = @i18.strings.twoFactor.disabled
    @n.getEl("#{sel.submit} > span")?.textContent = "Enable"
    @n.evaluateClass(sel.disable, "hide", yes)

onClickShowTwoFactor = (e)->
  @n.evaluateClass("[role='two-factor']", "hide", no)
  @n.evaluateClass(sel.show, "hide", yes)

onChangeTwoFactorCountry = (e)->
  countryCode = @n.getEl(sel.country)?.value
  preview = @$(sel.countryCodePreview).val('+' + countryCode)

UserAccountView = v = bQuery.view()

v.use view
  className: "user-account-view"
  template: require("./template")
  binder: 'property'

v.use passwordToggle
  selector: "[role='show-password']"
  className: "active"
  el:"[role='password']"

v.on "click [role='change-password']", (e)->
  password = @n.getEl("[role='password']")

  return unless password.value.length > 0

  btn = @n.getEl("[role='change-password']")
  btn.classList.add('active')

  finish = =>
    btn.classList.remove('active')
    password.value = ''

  @model.save
    password: password.value
  ,
    patch: true
    success: wait 500, @, (model, res, opts) =>
      finish()
      @toast("Password successfully updated.", 'success')

    error: wait 500, @, (model, res, opts) =>
      finish()
      @toast(parse.backbone.error(res).message, 'error')

v.ons
  "click #{sel.submit}": onSubmitTwoFactor
  "click #{sel.show}": onClickShowTwoFactor
  "click #{sel.disable}": onDisableTwoFactor
  "change #{sel.country}": onChangeTwoFactorCountry

v.init (opts={})->
  @subscription = opts.subscription

  if @permissions.canAccess('self.read.statementEmails', 'user.read.statementEmails')
    @sEmailsView = new InputListView
      model: @model
      property: "statementEmails"
      type: "email"
      placeholder: "example@monstercat.com"
      disabled: !@permissions.user.statementEmails.edit

  if @permissions.canAccess('self.read.shopInfoId', 'user.read.shopInfoid')
    shopOpts = _.omit(opts, 'model')
    shopOpts.model = new UserShopInfoModel _id: @model.get('shopInfoId')
    shopOpts.user = @model
    @shop = new UserShopInfoView(shopOpts)

  if @permissions.canAccess('self.read.whitelist', 'user.read.whitelist')
    # TODO Remove this external logic.
    @whitelistCollection = new UserWhitelistCollection null,
      user: @model

    @whitelistView = new UserWhitelistView
      user: @model
      subscription: @subscription
      collection: @whitelistCollection
      i18: @i18
      permissions: @permissions
    # Why does external view logic exist here?
    @whitelistView.on 'add:collection:view', (collection, el, model)=>
      @whitelistView.addNewView(el, model)

v.set "render", ->
  @renderer.locals.countries = countries.map((country)-> country.name)
  @renderer.locals.trialAccess = yes if @model.get('trialAccessEndDate')
  @renderer.locals.trialAccessEndDate = @model.getDateStr("trialAccessEndDate")
  @renderer.locals.countryCodes = callingCodes.map((country)-> {name: country.name, code: parseInt(country.dial_code)})

  @renderer.locals.trialAccess = yes if @model.get 'trialAccessEndDate'
  @renderer.locals.trialAccessEndDate = @model.getAsFormatedDate("trialAccessEndDate")
  @renderer.render()

  @$(sel.country).trigger('change')

  if @whitelistView?
    @whitelistCollection.toPromise().then =>
      @whitelistView.render()
    @el.appendChild(@whitelistView.el)

  if @sEmailsView?
    @sEmailsView.render()
    @n.getEl(".s-emails").appendChild(@sEmailsView.el)

  if @shop?
    @shop.render()
    @n.getEl('[role="shop-info"]')?.appendChild(@shop.el)

module.exports = v.make()
