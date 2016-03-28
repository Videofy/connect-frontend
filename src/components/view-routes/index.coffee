AccountsView       = require('accounts-view')
AssetsView         = require('assets-view')
ContractsView      = require('contracts-view')
ContractCreateView = require('contract-create-view')
ContractView       = require("contract-view")
DashboardView = require('dashboard-view')
ErrorView = require("error-view")
ForgotPasswordView = require("forgot-password-view")
GeneralPageView = require("general-page-view")
HandbookView = require("handbook-view")
LabelPageView = require("label-page-view")
LabelsView = require("labels-view")
MusicView = require("music-view")
ReleasesView = require("releases-view")
SignUpView = require("sign-up-view")
StatementsView = require("statements-view")
StylesView = require("styles-view")
TracksView = require("tracks-view")
UserInviteView = require("user-invite-view")
UserPageView = require('user-page-view')
UsersView = require('users-view')
UsersWhitelistView = require("users-whitelist-view")
VerifyView = require("verify-view")
WelcomeView = require("welcome-view")
SurveyView = require("survey-view")

redirect = (name, operative, session)-> ->
  # Allow:
  # auth is undefined = anyone
  # auth is true, anyone logged in.
  # auth is no, anyone not logged in
  # auth is [types], any types.

  { auth } = operative
  { user } = session
  authenticated = session.isAuthenticated()

  return "/music" if authenticated and auth is no
  return "/" if not authenticated and auth
  auth = [auth] if typeof(auth) is "string"
  return "/error" if user and auth?.length and _.intersection(auth, user?.type).length is 0

  undefined

module.exports = (scrollTarget, session, getOpts)->
  routes =
    accounts:
      auth: ['admin', 'label_admin']
      create: ->
        opts = getOpts()
        opts.collection = opts.dataSources.accounts
        opts.users = opts.dataSources.users
        return new AccountsView(opts)
      pattern: /^accounts\/?$/

    assets:
      auth: ['admin', 'label_admin']
      create: ->
        opts = getOpts()
        opts.collection = opts.dataSources.assets
        opts.users = opts.dataSources.users
        opts.accounts = opts.dataSources.accounts
        return new AssetsView(opts)
      pattern: /^assets\/?$/

    community:
      auth: ["admin", "admin_readonly", "label_admin"]
      create: ->
        opts = getOpts()
        opts.label = opts.dataSources.label
        opts.collection = opts.dataSources.users
        new UsersView(opts)
      pattern: /^community(?:\/|\/((?!create).*))?$/

    contractCreate:
      auth: ["admin", "admin_readonly", "label_admin"]
      create: ->
        opts = getOpts()
        ds = opts.dataSources
        opts.collection = ds.contracts
        opts.tracks = ds.tracks
        opts.user = ds.user
        opts.users = ds.users
        new ContractCreateView(opts)
      pattern: /^contracts\/create(?:\/|\/(.*))?$/

    contractView:
      auth: ["admin", "admin_readonly", "label_admin", "artist"]
      create: ->
        opts = getOpts()
        opts.collection = opts.dataSources.contracts
        new ContractView(opts)
      pattern: /^contracts\/view\/(.*)$/ 

    contracts:
      auth: ["admin", "admin_readonly", "label_admin", "artist"]
      create: ->
        opts = getOpts()
        opts.collection = opts.dataSources.contracts
        new ContractsView(opts)
      pattern: /^contracts\/?$/

    createUser:
      auth: ["admin", "label_admin"]
      create: ->
        opts = getOpts()
        opts.collection = opts.dataSources.users
        new UserInviteView(opts)
      pattern: /^community\/create\/?$/
    survey:
      auth: true
      create: ->
        opts = getOpts()
        new SurveyView(opts)
      pattern: /^subscription\/survey\/?$/

    dashboard:
      auth: yes
      create: ->
        opts = getOpts()
        opts.collection = opts.dataSources.newsStream
        new DashboardView(opts)
      pattern: /^dashboard\/?$/

    error:
      create: ->
        new ErrorView()
      pattern: /^error\/?$/

    forgotpassword:
      auth: no
      create: ->
        new ForgotPasswordView(getOpts())
      pattern: /^forgot-password(?:\/|\/(.*))?$/

    handbook:
      create: ->
        new HandbookView(getOpts())
      pattern: /^handbook(?:\/|\/(.*)(?:\/(.*))?)?$/

    labels:
      auth: "admin"
      create: ->
        opts = getOpts()
        opts.collection = opts.dataSources.labels
        new LabelsView(opts)
      pattern: /^labels\/?$/

    manage:
      auth: ["admin", "admin_readonly", "label_admin"]
      create: ->
        opts = getOpts()
        opts.model = opts.dataSources.label
        new LabelPageView(opts)
      pattern: /^manage\/?$/

    music:
      auth: yes
      create: =>
        opts = getOpts()
        opts.scrollTarget = scrollTarget
        opts.label = opts.dataSources.label
        opts.subscription = opts.dataSources.subscription
        opts.releases = opts.dataSources.releases
        opts.tracks = opts.dataSources.tracks
        new MusicView(opts)
      pattern: /^music(?:\/|\/(.*))?$/

    profile:
      auth: yes
      create: ->
        opts = getOpts()
        opts.model = opts.dataSources.user
        opts.subscription = opts.dataSources.subscription
        new UserPageView(opts)
      pattern: /^profile(?:\/|\/(.*))?$/

    releases:
      auth: ["admin", "admin_readonly", "label_admin"]
      create: ->
        opts = getOpts()
        opts.collection = opts.dataSources.releases
        opts.label = opts.dataSources.label
        opts.scrollTarget = scrollTarget
        new ReleasesView(opts)
      pattern: /^releases(?:\/|\/(.*))?$/

    signup:
      auth: no
      create: ->
        new SignUpView(getOpts())
      pattern: /^sign-up(?:\/|\/(.*))?$/

    statements:
      auth: ["admin", "admin_readonly", "label_admin", "artist"]
      create: ->
        opts = getOpts()
        opts.collection = opts.dataSources.statements
        new StatementsView(opts)
      pattern: /^statements\/?$/

    styles:
      auth: ["admin"]
      create: ->
        new StylesView(getOpts())
      pattern: /^styles\/?$/

    tracks:
      auth: ["admin", "admin_readonly", "label_admin"]
      create: ->
        opts = getOpts()
        opts.collection = opts.dataSources.tracks
        opts.label = opts.dataSources.label
        new TracksView(opts)
      pattern: /^tracks(?:\/|\/(.*))?$/

    verify:
      auth: no
      create: ->
        new VerifyView(getOpts())
      pattern: /^verify(?:\/|\/(.*))?$/

    whitelist:
      auth: ["admin", "admin_readonly", "label_admin"]
      create: ->
        opts = getOpts()
        opts.collection = opts.dataSources.users
        new UsersWhitelistView(opts)
      pattern: /^whitelist\/?$/

    welcome:
      auth: no
      create: ->
        opts = getOpts()
        new WelcomeView(opts)
      pattern: /(^(sign-in|gold|license|returned)?|^referral(?:\/|\/(.*))?)\/?$/

  for name, route of routes
    route.redirect = redirect(name, route, session) if !route.redirect

  routes
