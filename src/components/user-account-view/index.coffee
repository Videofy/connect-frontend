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
  country: '[role="country-code"]'
  countryCodePreview: '[role="country-code-preview"]'
  number: '[role="phone-number"]'

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
