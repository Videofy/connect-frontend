MenuView   = require("menu-view")
mobile     = require("is-mobile")
narrow     = require("is-narrow")
ToastsView = require("toasts-view")
View       = require("view-plugin")

ContainerView = v = bQuery.view()

v.use View
  className: "container-view"
  template: require("./template")

v.init (opts={})->
  { @dataSources, @session } = opts

  @menuView = new MenuView
    dataSources: @dataSources
    evs: opts.evs
    i18: opts.i18
    getSections: @getSections.bind(@)
    player: opts.player
    router: opts.router
    user: opts.user

  @toastsView = new ToastsView(opts)

  @evs.on("toggle-menu", @menuView.toggle.bind(@menuView))

v.set "render", ->
  @renderer.render()
  @contentEl = @el.querySelector(".content > .inner-content")

  @menuView.render()

  if @session.isAuthenticated() and !narrow()
    @menuView.el.classList.add("open")

  @el.insertBefore(@menuView.el, @el.firstChild)
  @el.appendChild(@toastsView.el)

v.set "getSections", ->
  arr = []

  return arr if !@session.isAuthenticated()

  admins = @getAdmin()
  defaults = @getDefaults()
  functions = @getFunctions()

  if admins.length
    arr.push(defaults)
    arr.push(admins)
    arr.push(functions)
  else
    arr.push([].concat(defaults, functions))

  arr.push({role: "playlists"})
  arr

v.set "getAdmin", ->
  user = @dataSources.user
  strings = @i18.strings.menu? or {}
  perms = @session.permissions or {}
  items = []

  if perms.canAccess('label.update')
    items.push
      name: strings["manage"] or "Manage Label"
      icon: "tag"
      route: "manage"
      url: "#manage"

  if perms.canAccess('label.create')
    items.push
      name: strings["labels"] or "All Labels"
      icon: "tags"
      route: "labels"
      url: "#labels"

  if perms.canAccess('gui.panel.admin')
    items.push
      name: strings["assets"] or "Assets"
      icon: "cubes"
      route: "assets"
      url: "#assets"

    items.push
      name: strings["tracks"] or "Tracks"
      icon: "music"
      route: "tracks"
      url: "#tracks"

    items.push
      name: strings["releases"] or "Releases"
      icon: "book"
      route: "releases"
      url: "#releases"

    items.push
      name: strings["users"] or "Users"
      icon: "group"
      route: "community"
      url: "#community"

    items.push
      name: strings["accounts"] or "Accounts"
      icon: "group"
      route: "accounts"
      url: "#accounts"

    items.push
      name: strings["whitelist"] or "Whitelist"
      icon: "flag"
      route: "whitelist"
      url: "#whitelist"

  items

v.set "getDefaults", ->
  strings = @i18.strings.menu? or {}
  perms = @session.permissions or {}
  items = []

  items.push
    name: "Account"
    icon: "user"
    route: "profile"
    url: "#profile"

  items.push
    name: strings["dashboard"] or "Dashboard"
    icon: "dashboard"
    route: "dashboard"
    url: "#dashboard"

  items.push
    name: strings["music"] or "Music"
    icon: "headphones"
    route: "music"
    url: "#music"

  if perms.canAccess('contracts.read')
    items.push
      name: strings["contracts"] or "Contracts"
      icon: "qrcode"
      route: "contracts"
      url: "#contracts"

  if perms.canAccess('statements.view')
    items.push
      icon: "inbox"
      name: strings["statements"] or "Statements"
      route: "statements"
      url: "#statements"

  items

v.set "getFunctions", ->
  strings = @i18.strings.menu? or {}
  perms = @session.permissions?.views
  items = []

  items.push
    name: strings['help'] or "Feedback"
    icon: "question"
    callback: -> window.Intercom?('show')

  items.push
    name: strings["handbook"] or "Handbook"
    icon: "info"
    route: "handbook"
    url: "#handbook"

  if (@dataSources.label?.get("name") or "").toLowerCase() is "monstercat"
    items.push
      name: strings["branding"] or "Branding Assets"
      icon: "briefcase"
      url: "http://monstercat.com/essentials"
      target: "_blank"

  if @session.isAuthenticated()
    items.push
      name: strings["logout"] or "Sign Out"
      icon: "sign-out"
      url: "#signout"

  items

module.exports = v.make()
