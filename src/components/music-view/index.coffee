InputClear               = require("input-clear-plugin")
MusicPodcastsView        = require("music-podcasts-view")
MusicReleasesView        = require("music-releases-view")
MusicTracksView          = require("music-tracks-view")
SubscriptionRequiredView = require("subscription-required-view")
TabView                  = require("tab-view")
tabChange                = require("tab-change-plugin")
view                     = require("view-plugin")
TrackCollection          = require('track-collection')
ReleaseCollection        = require('release-collection')

onFinishLoad = ->
  @n.getEl("[role='loader']").classList.add("hide")
  @n.getEl("nav").classList.remove("hide")
  @n.getEl(".content").classList.remove("hide")

onClickNext = (e)->
  view = @tabs.config[@tabs.active].view
  view.setPage?(view.page.index + 1).then =>
    @updatePagination(view)

onClickPrevious = (e)->
  view = @tabs.config[@tabs.active].view
  view.setPage?(view.page.index - 1).then =>
    @updatePagination(view)

MusicView = v = bQuery.view()

v.use view
  className: "music-view"
  template: require("./template")

v.use InputClear
  callback: "delayQuery"

v.ons
  "keyup [role='filter']": "delayQuery"
  "click [role='page-next']": onClickNext
  "click [role='page-previous']": onClickPrevious

v.init (opts={})->
  { @user, @router, @subscription, @tracks, @releases } = opts

  throw Error('No user.') unless @user
  throw Error('No router.') unless @router

  opts = _.clone(opts)
  @requireView = new SubscriptionRequiredView(opts)
  @tabs = new TabView
  @tabs.active = "catalog"
  @tabs.set
    releases:
      title: "Releases"
      view: new MusicReleasesView(opts)
    catalog:
      title: "Catalog"
      view: new MusicTracksView(opts)
    podcasts:
      title: "Podcasts"
      view: new MusicPodcastsView(opts)

v.use tabChange
  page: "profile"
  onQuery: (view, needle, reset)->
    @n.setText("[role='filter']", needle) if reset
    promise = @tabs.config[view].view.filter?(needle)
    promise?.then =>
      @updatePagination(@tabs.config[@tabs.active].view)

v.set "render", ->
  @renderer.render()
  @tabs.content = @n.getEl(".content")
  @tabs.render()
  @n.getEl(".tabs").appendChild(@tabs.el)

  if @user.requiresSubscription(@subscription)
    @requireView.render()
    @el.appendChild(@requireView.el)
    @el.style.overflow = "hidden" # Move to CSS

  @tracks.toPromise().then =>
    onFinishLoad.call(@)

  @tabs.hide('podcasts', !@permissions.canAccess('gui.catalog.podcasts'))
  @tabs.hide('releases', !@permissions.canAccess('gui.catalog.releases'))
  @tabs.hide('catalog', !@permissions.canAccess('gui.catalog.tracks'))

v.set "delayQuery", (e)->
  if @keyTimer
    clearTimeout(@keyTimer)

  @keyTimer = setTimeout =>
    @query(@tabs.active, e.target.value, false)
    delete @keyTimer
  , 300

v.set "updatePagination", (view)->
  @n.evaluateClass('.table-pagination', 'no-pages', !view.page or
    (view.page.start is 0 and
      view.page.start + view.page.increment >= view.page.results.length))
  @n.evaluateDisabled('[role="page-previous"]', !view.canPageBackward?())
  @n.evaluateDisabled('[role="page-next"]', !view.canPageForward?())

  text = ""
  if view.page
    page = view.page
    total = page.results.length
    if total > 0
      start = page.start + 1
      end  = page.start + page.increment
      end = total if end > total
      text = "#{start} - #{end} of #{total}"
    else
      text = "No Results"

    @n.setText('[role="page-next"] [role="increment"]', page.increment)
    @n.setText('[role="page-previous"] [role="increment"]', page.increment)
  else if view.filterCount
    text = if isNaN(view.filterCount) then "" else
      "#{view.filterCount} Results"

  @n.setText('[role="results"]', text)

v.set "updateLocation", ->
  url = "music/#{@tabs.active}/#{encodeURIComponent(@needle or "")}"
  @router.navigate url,
    trigger: false
    replace: true

module.exports = v.make()
