analytics        = require("analytics")
AudioPlayer      = require("audio-player")
ContainerView    = require("container-view")
DataSources      = require("data-sources")
debug            = require("debug")("connect")
EndPoint         = require('end-point')
getViewRoutes    = require("view-routes")
I18              = require("i18")
MastView         = require("mast-view")
PlayerView       = require("player-view")
Router           = require("router")
Session          = require("session")
Transfers        = require("transfers")
UserCompleteView = require('user-complete-details-view')
ViewRouter       = require("view-router")
welcome          = require("welcome")
shortcuts        = require("shortcuts")

getVolume = ->
  return 1 if not store = window.localStorage
  (store.getItem("volume") or 1) * 1

setVolume = (volume)->
  return if not store = window.localStorage
  store.setItem("volume", volume)

class Connect

  constructor: (uri, analyticsjs)->
    welcome()
    _.extend(@, Backbone.Events)
    EndPoint.base = uri

    @analytics = analyticsjs
    @el = document.createElement("div")
    @el.className = "connect"

    @ap = new AudioPlayer # A global player for the main controls.
    @ap.volume(getVolume())
    @pap = new AudioPlayer # A private player for individual controls.

    # Bounce the players controls when they change.
    @pap.continuous = false
    @ap.on "play", => @pap.stop()
    @ap.on "volume", (item, volume)=>
      @pap.volume(volume)
      setVolume(volume)
    @pap.on "play", => @ap.stop()

    @sse = new EventSource(EndPoint.url("/events"), {withCredentials: true})
    @transfers = new Transfers(@)
    @dataSources = new DataSources
    @i18 = new I18
    @router = new Router(@)

    shortcuts(@ap)

    @session = new Session
      urlRoot: EndPoint.base
    @viewRouter = new ViewRouter(@router, @)
    @load()

  displayError: (err)->
    @el.classList.add("error")
    @el.innerHTML = "<p>#{err.message}</p><p><a href=\".\">Click here to refresh</a>.</p>"

  load: ->
    @session.load (err)=>
      return @displayError(Error('An error occured while loading your session.')) if err
      locale = @session.user?.locale or "en"
      @i18.load "/locale/#{locale}.json", (err)=>
        return @initialize() unless err
        @displayError(Error('An error occured while loading the locale file.'))

  initialize: ->
    @updateData()
    @render()
    Backbone.history.start
      pushState: false

  render: ->
    @containerView = new ContainerView(@getOptions())
    @containerView.render()

    @viewRouter.set(@containerView.contentEl,
      getViewRoutes(@containerView.contentEl, @session, @getOptions.bind(@)))

    @router.route("signout", "signout", @signout.bind(@))

    canViewTransfers = @session.isAuthenticated() and
      @session.permissions.release.view

    @mastView = new MastView
      evs: @
      player: @ap
      transfers: if canViewTransfers then @transfers else undefined
      user: @dataSources.user
      i18: @i18
    @mastView.render()
    @mastView.setLabel(@dataSources.label)
    @mastView.n.evaluateClass("hide", !@session.isAuthenticated())

    @playerView = new PlayerView
      evs: @
      i18: @i18
      player: @ap
      playlists: @dataSources.playlists
      releases: @dataSources.releases
      tracks: @dataSources.tracks
    @playerView.render()
    @playerView.n.evaluateClass("hide", !@session.isAuthenticated())

    @el.insertBefore(@playerView.el, @el.firstChild)
    @el.insertBefore(@containerView.el, @el.firstChild)
    @el.insertBefore(@mastView.el, @el.firstChild)

    return unless @session.isAuthenticated()

    user = @dataSources.user
    if missing = user.getMissingFields()
      completeView = new UserCompleteView
        model: user
        permissions: @session.permissions
      completeView.render()
      @el.appendChild(completeView.el)
      completeView.on 'close', ->
        completeView.el.parentElement.removeChild(completeView.el)

  updateData: ->
    if @session.isAuthenticated()
      @dataSources.setUser(@session.user)
      @dataSources.setLabel(@session.label)
      @dataSources.setSubscription(@session.subscription)

    if @analytics?
      analytics
        analytics: @analytics
        events: @
        user: @dataSources.user
        player: @ap

  getOptions: ->
    dataSources: @dataSources
    evs: @
    i18: @i18
    permissions: @session.permissions or {}
    player: @ap
    privatePlayer: @pap
    router: @router
    session: @session
    sse: @sse
    transfers: @transfers
    user: @dataSources.user
    subscription: @dataSources.subscription

  signout: ->
    @trigger("signout")
    @session.destroy ( err ) =>
      @router.open("/") unless err

module.exports = Connect
