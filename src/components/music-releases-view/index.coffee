DateTime                 = require("date-time")
MusicReleasesPreviewView = require("music-releases-preview-view")
MusicTracksTable         = require("music-tracks-table-plugin")
menu                     = require("release-context-menu-plugin")
mobile                   = require("is-mobile")
narrow                   = require("is-narrow")
view                     = require("view-plugin")

getReleaseGenres = (tracks)->
  arr = []
  tracks.forEach (track)->
    genre = track.attributes.genre
    if !(genre in arr)
      arr.push(genre)
  arr

getReleaseTracks = (release, tracks)->
  tracks.filter (track)->
    rids = (track.attributes.albums or []).map (item)-> item.albumId
    release.id in rids and release.isTrackReleased(track)

getReleases = (releases, tracks)->
  arr = releases.models.map (release)->
    tks = getReleaseTracks(release, tracks)
    o = _.clone(release.attributes)
    o.date = new Date(o.releaseDate or o.released)
    o.numTracks = tks.length
    o.coverArt = release.coverUrl(128)
    o.released = release.isReleased()

    o.queryables =
      rid: o._id
      title: o.title
      genres: getReleaseGenres(tks)
      artists: o.renderedArtists
      date: DateTime.format("F j, Y", o.date)
      type: o.type
    o

  arr.filter (release)->
    return false if release.type is "Podcast" or
      isNaN(release.date.getTime())
    true

sortReleases = (arr)->
  arr.sort (a, b)->
    return -1 if a.date > b.date
    return 1 if a.date < b.date
    0

getTrackIds = (el, tracks, releases)->
  id = undefined
  target = el
  while not id and target
    id = target.getAttribute("release-id")
    target = target.parentElement

  arr = []
  tracks.forEach (track)->
    rids = (track.attributes.albums or []).map (item)-> item.albumId
    if id in rids
      album = _.find track.attributes.albums, (item)-> item.albumId is id
      arr.push
        track: track
        release: releases.get(album.albumId)
        order: album.trackNumber

  arr.sort (a, b)->
    return -1 if a.order < b.order
    return 1 if a.order > b.order
    0

findReleaseEl = (target)->
  while target
    return target if target.getAttribute("release-id")
    target = target.parentElement

onClick = (e, openPreview=true)->
  el = findReleaseEl(e.target)

  return if el is @preview.el
  id = el?.getAttribute("release-id")

  if not id or (@preview.releaseId is id and @preview.isOpen())
    return @preview.close()

  @preview.set(id) if @preview.releaseId isnt id
  @preview.open() if openPreview

onClickPlay = (e)->
  onClick.call(this, e, false)
  @preview.playFirst(true)

onClickToggleView = ->
  el = @n.getEl("[role='releases']")
  el.classList.toggle("grid-view")
  @n.getEl("[role='list-view']").classList.toggle("active")
  @n.getEl("[role='grid-view']").classList.toggle("active")
  @style = if el.classList.contains('grid-view') then 'grid' else 'list'

onDragStartRelease = (e)->
  e = e.originalEvent
  return if not ids = getTrackIds(e.target, @tracks, @releases)
  tids = ids.map (item)-> item.track.id
  rids = ids.map (item)-> item.release.id
  e.dataTransfer.setData("text/track-ids", tids.join(","))
  e.dataTransfer.setData("text/release-ids", rids.join(","))
  @evs.trigger("openplaylist")
  @evs.trigger("dragtracks:start", ids)
  @isDragging = true

onDragEndRelease = (e)->
  return if not @isDragging
  delete @isDragging
  @evs.trigger("dragtracks:end")

MusicReleasesView = v = bQuery.view()

v.use view
  className: "music-releases-view"
  template: require("./template")

v.use menu
  ev: "click td [role='download-release']"
  from: "MusicReleasesView"
  getRelease: (source)->
    @releases.get(findReleaseEl(source).getAttribute("release-id"))

v.ons
  "click [role='open-release']": onClick
  "click [role='play-release']": onClickPlay
  "click [role='list-view']": onClickToggleView
  "click [role='grid-view']": onClickToggleView
  "dragstart .releases td img": onDragStartRelease
  "dragend .releases td img": onDragEndRelease

v.init (opts={})->
  { @player } = opts
  @releases = opts.releases
  @tracks = opts.tracks
  @preview = new MusicReleasesPreviewView(opts)
  @style = 'grid'
  @page =
    index: 0
    start: 0
    increment: 24
  @player.on "play", @displayReleasePlaying.bind(@)

v.set "render", ->
  { page, renderer } = @

  @style = 'list' if narrow(725)

  renderer.locals.mode = "loading"
  renderer.locals.mobile = mobile()
  renderer.locals.style = @style
  renderer.render()
  @releases.toPromise()
  .then => @tracks.toPromise()
  .then =>
    releases = sortReleases(MusicTracksTable.filter(@getReleases(), @needle))

    renderer.locals.mode = "view"
    renderer.locals.releases = releases.slice(page.start,
      page.start + page.increment)
    renderer.render()
    @preview.render()
    @el.appendChild(@preview.el)

    page.results = releases
    @displayReleasePlaying()

v.set 'setPage', (index)->
  index = 0 if (index < 0)
  @page.index = index
  @page.start = index * @page.increment
  @render()

v.set 'canPageBackward', ->
  @page.start >= @page.increment and @page.results?.length

v.set 'canPageForward', ->
  @page.start + @page.increment < @page.results?.length

v.set "getReleases", ->
  @cache = getReleases(@releases, @tracks) if not @cache
  @cache

v.set "filter", (@needle)->
  @render()

v.set "displayReleasePlaying", ->
  return if not tracks = @n.getEl("tbody")

  if @player.audio and not @player.audio.paused
    rid = @player.playlist.get("tracks")[@player.index].releaseId

  for tr in tracks.children
    @n.evaluateClass(tr, "playing", tr.getAttribute("release-id") is rid)

module.exports = v.make()
