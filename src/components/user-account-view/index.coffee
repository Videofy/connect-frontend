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

onSubmitTwoFactor = (e)->
  number = @n.getEl('[role="phone-number"]')?.value
  countryCode = @n.getEl(['[role="country-code"]'])?.value
  @n.evaluateClass("[role='submit-two-factor']", "active", yes)
  @model.setTwoFactor number, countryCode, (err)=>
    @n.evaluateClass("[role='submit-two-factor']", "active", no)
    return @toast(err.message, 'error') if err
    @toast('Two Factor settings updated.')
    @n.getEl('[role="two-factor-status"]')?.textContent = @i18.strings.twoFactor.enabled
    @n.getEl('[role="submit-two-factor"] > span')?.textContent = 'Update'

onClickShowTwoFactor = (e)->
  @n.evaluateClass("[role='two-factor']", "hide", no)
  @n.evaluateClass("[role='show-two-factor']", "hide", yes)

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
  'click [role="submit-two-factor"]': onSubmitTwoFactor
  'click [role="show-two-factor"]': onClickShowTwoFactor

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
