mobile = require("is-mobile")
narrow = require("is-narrow")
PlaylistsView = require("playlists-view")
View = require("view-plugin")

onRoute = (route, params)->
  @displayActive(route)

onClickItem = (e)->
  n = e.currentTarget.getAttribute('item-index')
  i = e.currentTarget.getAttribute('section-index')
  item = @renderer.locals.sections[i][n]

  item.callback?()

  @close() if narrow()

MenuView = v = bQuery.view()

v.use View
  className: "menu-view"
  template: require("./template")

v.ons
  "click a.item": onClickItem

v.init (opts={})->
  { @getSections, @dataSources, @router } = opts

  @playlists = new PlaylistsView
    collection: @dataSources.playlists
    evs: opts.evs
    i18: opts.i18
    player: opts.player
    tracks: @dataSources.tracks
    releases: @dataSources.releases

  @router.on "route", onRoute.bind(@)
  @evs.on "openmenu", @open.bind(@)
  @evs.on "closemenu", @close.bind(@)

v.set "render", ->
  @renderer.locals.sections = @getSections()
  @renderer.render()

  if pltarget = @n.getEl("[role='playlists']")
    @playlists.render()
    pltarget.appendChild(@playlists.el)

v.set "displayActive", (route)->
  els = @el.querySelectorAll(".menu-set a.item")
  for el in els
    el.classList.remove('active')
  el = @el.querySelector(".menu-set a.item[route='#{route}']")
  el && el.classList.add("active")

v.set "toggle", ->
  @el.classList.toggle("open")
  @evs.trigger("closeplaylist") if @el.classList.contains("open") and narrow()

v.set "open", ->
  @el.classList.add("open")
  @evs.trigger("closeplaylist") if narrow()

v.set "close", ->
  @el.classList.remove("open")

module.exports = v.make()