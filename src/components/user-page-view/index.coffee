SubscriptionModel          = require('subscription-model')
UserSubscriptionView       = require("user-subscription-view")
TabView                    = require("tab-view")
UserAccountView            = require("user-account-view")
UserAdminView              = require("user-admin-view")
UserBillingView            = require("user-billing-view")
UserWebsiteDetailsView     = require("user-website-details-view")
UserLogsView               = require("user-logs-view")
UserLogsCollection         = require("user-log-collection")
UserPaymentsCollection     = require("user-payments-collection")
SubBillingView             = require("user-sub-billing")
tabChange                  = require("tab-change-plugin")
WebsiteDetailsModel        = require("website-details-model")
UserArticlesView           = require('./articles-view')
UserWhitelistView          = require('user-whitelist-info-view')
ArticleCollection          = require('article-collection')
view                       = require("view-plugin")

UserPageView = v = bQuery.view()

v.use view
  className: "user-page-view"
  template: require("./template")

v.init (opts={})->
  throw Error('Model required.') unless @model

  @logsCollection = new UserLogsCollection null, user: @model if @permissions.user.logs

  if @model.isSubscriber()
    subscriptionModel = opts.subscription or new SubscriptionModel
    subscriptionModel.set('_id', @model.get('subscriptionModelId'))
    opts.subscription = subscriptionModel
    @billingCollection = new UserPaymentsCollection null, subscription: subscriptionModel

  subOpts = _.extend _.clone(opts),
    model: subscriptionModel
    user: @model

  wopts = _.extend _.clone(opts),
    _id: @model.get('websiteDetailsId')
    user: @model
    model: new WebsiteDetailsModel

  @tabs = new TabView
  @tabs.active = "account"
  tabSections =
    admin:
      title: "Admin"
      view: new UserAdminView(opts)
    account:
      title: "Account"
      view: new UserAccountView(opts)
    website:
      title: "Website Info"
      view: new UserWebsiteDetailsView(wopts)
    billing:
      title: "Billing Details"
      view: new UserBillingView(opts)
    docs:
      title: "Documents"
      view: new UserArticlesView
        collection: new ArticleCollection null,
          by:
            key: 'userId'
            value: @model.id
    logs:
      title: "User Logs"
      view: new UserLogsView
        model: @model
        collection: @logsCollection

  if @permissions.canAccess('user.subscription', 'self.subscription') and @model.isSubscriber()
    tabSections.subscription =
      title: "Subscription"
      view: new UserSubscriptionView(subOpts)

  if @permissions.canAccess('user.read.whitelist') and @model.isOfTypes('licensee')
    tabSections.whitelist =
      title: "Whitelist"
      view: new UserWhitelistView _.extend _.clone(opts),
            model: @model
            subscription: subscriptionModel

  if @permissions.canAccess('user.subBilling', 'self.billing') and @model.isSubscriber()
    tabSections.subBilling =
      title: "Billing History"
      view: new SubBillingView
        model: @model
        collection: @billingCollection
        i18: @i18

  @tabs.set tabSections

v.use tabChange
  page: "profile"

v.set "render", ->
  @stopListening(@model)
  @renderer.locals.mode = 'loading'
  @renderer.render()
  @model.toPromise(true).then =>
    @renderer.locals.mode = 'view'
    @renderer.render()
    @tabs.render()
    @el.appendChild(@tabs.el)
    @onTypeChange()
    @listenTo @model, "change:type", @onTypeChange.bind(@)

v.set "onTypeChange", ->
  return if not @el.firstChild
  @tabs.hide("admin", !@permissions.canAccess('user.read.type'))
  @tabs.hide("billing", !@permissions.canAccess('self.read.paymentType', 'user.read.paymentType'))
  @tabs.hide("website", !@permissions.canAccess('websiteDetails.update'))
  @tabs.hide("logs", !@permissions.canAccess('user.logs'))
  @tabs.hide("docs", !@permissions.canAccess('statements.view'))

module.exports = v.make()

