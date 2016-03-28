view          = require("view-plugin")
request       = require("superagent")
DateTime      = require("date-time")
ShareCodeView = require("share-code-view")
v             = bQuery.view()

socialLinks =
  fb:
    tag: "[role='share-fb']"
    apiUrl: "https://www.facebook.com/sharer/sharer.php?u="
  tw:
    tag: "[role='share-tw']"
    apiUrl: "https://twitter.com/intent/tweet"
  gplus:
    tag: "[role='share-gplus']"
    apiUrl: ""

sel =
  addCoupon: "[role='add-coupon']"

v.use view
  className: "subscription-referral-view"
  template: require("./template")

v.init (opts={})->
  @shareCodeView = new ShareCodeView(opts)
  @user = opts.user

v.set "render", ->
  @user.getReferralUrl (err, url)=>
    @collection.toPromise().then =>
      @referrals = @collection.models.map (model)->
        createdDate: model.getAsFormatedDate('createdDate')
        referredEmail: model.get('referredEmail')
        referrerDiscountAmount: model.get('referrerDiscountAmount')

      @renderer.locals.code = url
      @renderer.locals.discount = if @user.isOfTypes("golden") then 10 else 15
      @renderer.locals.referrals = @referrals
      @renderer.render()
      @updateView()

v.set 'addCoupon', ->
  @shareCodeView.render()

v.set 'shareUrl', ->
  shareCode = @user.get 'subscriptionReferralCode'
  return "Sign up the subscription and get discount! #{@url}"

v.set 'updateView', ->
  @setShareLink()

v.set 'setShareLink', ->
  for key, value of socialLinks
    el = @el.querySelector("#{value.tag}")
    el.href = value.apiUrl+ @shareUrl() if el

module.exports = v.make()
