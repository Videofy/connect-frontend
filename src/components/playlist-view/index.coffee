ContextMenu      = require("context-menu-plugin")
DragDetector     = require("drag-detector")
DragTracksToggle = require("drag-tracks-toggle-plugin")
formats          = require("formats")
mobile           = require("is-mobile")
PlaylistModel    = require("playlist-model")
PresenterView    = require("presenter-view")
TrackCreditView  = require("track-credit-view")
View             = require("view-plugin")

isPlaylistSame = (a, b)->
  a and b and (a is b or (a.id and a.id is b.id))

getTrackPosition = (x, y, el)->
  parent = el.parentElement
  frame = parent.getBoundingClientRect()

  x: x - frame.left
  y: y - frame.top + (el.getBoundingClientRect().height * 0.5)

setTrackPosition = (el, e)->
  pos = getTrackPosition(e.clientX, e.clientY, el)
  el.style.left = "0px"
  el.style.top = pos.y + "px"

# Duplicate code. Refactor!
makeId = (tid, rid)->
  "#{tid}:#{rid}"

# Duplicate code. Refactor!
find = (el)->
  target = el
  while target
    break if target.getAttribute("track-id") and target.getAttribute("release-id")
    target = target.parentElement
  target

# Duplicate code. Refactor!
getTrackInfo = (el, tracks, releases)->
  return undefined if not target = find(el)

  tid = target.getAttribute("track-id")
  rid = target.getAttribute("release-id")

  track: tracks.get(tid)
  release: releases.get(rid)
  lost: !!target.getAttribute("lost")
  trackId: tid
  releaseId: rid

onClickRename = ->
  if name = prompt(@i18.strings.playlist.newMsg,
                    @playlist.get("name"))
    @playlist.save name: name,
      error: (model, res, opts)=>
        @evs.trigger "toast",
          text: @i18.strings.playlist.errorMsg
          theme: error
          time: 2500

PlaylistView = v = bQuery.view()

v.use View
  className: "playlist-view"
  template: require("./template")

v.use ContextMenu
  evs: ["click [role='options']", "contextmenu"]

v.use ContextMenu
  name: "downloadPlaylistContextMenu"
  ev: "click [role='download']"

v.use DragTracksToggle()

v.ons
  "click [role='rename']": onClickRename
  "click [role='save']": "onClickSave"
  "click [role='clear']": "onClickClear"
  "click [role='new']": "onClickNew"

v.init (opts={})->
  { @player, @user, @tracks, @releases, @playlists } = opts
  @cbs = @generateCallbacks()

  @evs.on "changeplaylist", @onChangePlaylist.bind(@)

  # WARNING Duplicate Code
  @creditsPresenter = new PresenterView
  @creditsPresenter.el.classList.add("track-credit", "flexi")
  @on "render", => @creditsPresenter.attach()

v.set "generateCallbacks", ->
  drag = @onDrag.bind(@)
  change = @onChangePlayer.bind(@)
  player:
    add: change
    remove: change
    play: change
  track:
    click: @onClickTrack.bind(@)
    mousedown: @onMouseDownTrack.bind(@)
  drop:
    dragenter: drag
    dragleave: drag
    dragover: drag
    drop: @onDrop.bind(@)
  playlist:
    change:
      name: @renderPlaylistName.bind(@)
      tracks: @onChangePlaylistTracks.bind(@)
    destroy: @onDestroyPlaylist.bind(@)

v.set "remove", ->
  Backbone.View.prototype.remove.apply(@, arguments)
  for key, value of @cbs.player
    @player.off(key, value)

v.set "delegateEvents", ->
  Backbone.View.prototype.delegateEvents.apply(@, arguments)
  for key, value of @cbs.player
    @player.on(key, value)

v.set "render", ->
  @renderer.locals.mobile = mobile()
  @renderer.locals.tracks = []
  @renderer.render()

  (new DragDetector(@n.getEl('.drop-zone'), @el)).listen()

  dropel = @el
  for key, value of @cbs.drop
    dropel.addEventListener(key, value)

  @renderPlaylistName()
  @grabAndRenderTracks()

v.set "grabAndRenderTracks", ->
  if @playlist
    if @tracks.length is 0 or @releases.length is 0
      @renderer.locals.mode = "loading"
      @renderer.render()

    @playlist.grabTracks(@tracks, @releases)
    .then => @releases.toPromise()
    .then =>
      @renderer.locals.mode = "view"
      @renderer.render()
      @renderTracks()
  else
    @renderTracks()

v.set "renderPlaylistName", ->
  @n.setText("[role='playlist-name']", @playlist.get("name")) if @playlist

v.set "renderMast", ->
  hasPlaylist = !!@playlist
  hasTracks = hasPlaylist and @playlist.tracks.length
  isNew = hasPlaylist and @playlist.isNew()
  @n.evaluateClass(".mast", "hide", !hasPlaylist)
  @n.evaluateClass("[role='create-playlist-msg']", "hide", hasPlaylist)
  @n.evaluateClass("[role='add-tracks-msg']", "hide",
    !hasPlaylist or hasTracks)
  @n.evaluateClass("[role='rename']", "hide", !hasPlaylist or isNew)
  @n.evaluateClass("[role='save']", "hide", !isNew or (isNew and !hasTracks))
  @n.evaluateClass("[role='clear']", "hide", !hasTracks)
  @n.evaluateClass("[role='new']", "hide", isNew or !hasTracks)

v.set "renderTracks", ->
  tracksEl = @n.getEl("[role='tracks']")
  while tracksEl.firstChild
    child = tracksEl.firstChild
    child.removeEventListener("dblclick", @cbs.track.click) if !mobile()
    child.remove()

  if not (!!@playlist and @playlist.tracks.length)
    @renderMast()
    return

  tracks = []
  for item, i in @playlist.get("tracks")
    tmodel = @tracks.get(item.trackId)
    rmodel = @releases.get(item.releaseId)

    if !tmodel or !rmodel
      track =
        index: i
        lost: true
        releaseId: item.releaseId
        trackId: item.trackId
    else
      track =
        artists: tmodel.get("artistsTitle")
        genre: tmodel.get("genre")
        index: i
        release: rmodel.get("title")
        releaseId: item.releaseId
        title: tmodel.get("title")
        trackId: item.trackId

    tracks.push track

  @renderer.locals.tracks = tracks
  @renderer.render()

  tracksEl = @n.getEl("[role='tracks']")
  tracksEl.addEventListener("mouseup", @onMouseUp.bind(@))
  tracksEl.addEventListener("mousemove", @onMouseMove.bind(@))
  for child in tracksEl.children
    child.addEventListener("mousedown", @cbs.track.mousedown)
    child.addEventListener("dblclick", @cbs.track.click) if !mobile()

  @renderMast()
  @renderPlaylistName()
  @displayActive()

# Modified duplicate code. Refactor!
v.set "displayActive", ->
  return if not  tracks = @n.getEl("[role='tracks']")

  id = undefined
  if isPlaylistSame(@playlist, @player.playlist)
    item = @player.playlist.get("tracks")[@player.index] or {}
    id = makeId(item.trackId, item.releaseId)

  for tr, i in tracks.children
    iid = makeId(tr.getAttribute("track-id"), tr.getAttribute("release-id"))
    @n.evaluateClass(tr, "active", !!(id and iid is id))

v.set "displayError", (value)->
  sel = "[role='error']"
  @n.evaluateClass(sel, "hide", !value)
  @n.setText(sel, value)

v.set "updatePlayer", ->
  @playlist.grabTracks(@tracks, @releases).then =>
    @player.set(@playlist.getPlayerItems())
    @player.playlist = @playlist

v.set "setPlaylist", (playlist)->
  if @playlist
    @playlist.off("change:name", @cbs.playlist.change.name)
    @playlist.off("change:tracks", @cbs.playlist.change.tracks)
    @playlist.off("destroy", @cbs.playlist.destroy)
    delete @playlist

  if playlist
    @playlist = playlist
    @playlist.on("change:name", @cbs.playlist.change.name)
    @playlist.on("change:tracks", @cbs.playlist.change.tracks)
    @playlist.on("destroy", @cbs.playlist.destroy)

  if not @player.playlist
    @updatePlayer()

  @render()

v.set "removeTrackById", (trackId, releaseId)->
  @playlist.removeTrack(trackId, releaseId)
  @playlist.update()

v.set "setMovingTrack", (el)->
  if el
    el.classList.add("moving")
    @movingEl = el
  else if @movingEl
    @movingEl.classList.remove("moving")
    delete @movingEl

v.set "reorderMovingTrack", ->
  target = @movingEl
  tracks = @n.getEl("[role='tracks']")
  tframe = target.getBoundingClientRect()
  insertTarget = undefined

  for li, i in tracks.children
    continue if li is target
    lframe = li.getBoundingClientRect()

    if tframe.top + tframe.height > lframe.top and tframe.top < lframe.top
      insertTarget = li
      break

  if insertTarget
    target.parentElement.insertBefore(target, insertTarget)
    arr = []
    for li, i in tracks.children
      arr.push
        trackId: li.getAttribute("track-id")
        releaseId: li.getAttribute("release-id")
    @playlist.set("tracks", arr)
    @playlist.update()
    @updatePlayer() if isPlaylistSame(@player.playlist, @playlist)

v.set "onClickTrack", (e)->
  @updatePlayer().then =>
    index = e.target.getAttribute("index")
    @player.play(parseInt(index))
    @evs.trigger "closeplaylist" if index and mobile()

v.set "onClickSave", ->
  return if not @playlist and not @playlist.isNew()

  if name = prompt(@i18.strings.playlist.newMsg,
                    @playlist.get("name"))
    @playlist.set("name", name)
    @playlist.save()
    @playlists.add(@playlist)

v.set "onClickClear", ->
  return if not confirm("Are you sure you want to remove all tracks from this playlist?")

  @playlist.clearTracks()
  @playlist.update()
  @renderTracks()

v.set "onClickNew", ->
  p = new PlaylistModel()
  @evs.trigger("changeplaylist", p)

v.set "onChangePlayer", ->
  @displayActive()

v.set "onChangePlaylist", (playlist)->
  @setPlaylist(playlist) if playlist
  @displayActive()

v.set "onDestroyPlaylist", (playlist) ->
  @setPlaylist() if playlist is @playlist

v.set "onChangePlaylistTracks", ->
  @grabAndRenderTracks()

v.set "onDrag", (e)->
  e.preventDefault()

v.set "onDrop", (e)->
  e.preventDefault()

  tids = e.dataTransfer.getData("text/track-ids").split(",")
  rids = e.dataTransfer.getData("text/release-ids").split(",")
  tracks = (tids.map (id)=> @tracks.get(id)).filter (track)-> !!track
  releases = (rids.map (id)=> @releases.get(id)).filter (release)-> !!release

  return if not tracks.length or tracks.length isnt releases.length

  created = false
  playlist = @playlist

  if not playlist
    playlist = new PlaylistModel
    created = true

  tracks.forEach (track, index, arr)->
    playlist.addTrack(track, releases[index])

  playlist.update()

  @evs.trigger("changeplaylist", playlist) if created

v.set "onOpenContextMenu", (source, menu)->
  clearTimeout(@downtimer)

  if source.getAttribute('role') is 'options'
    @openTrackContextMenu(source, menu)
  else
    @openPlaylistContextMenu(source, menu)

v.set "openPlaylistContextMenu", (source, menu)->
  return unless @playlist?

  items = formats.defaults.map (format)=>
    name: format.name
    anchor:
      download: true
      url: @playlist.downloadUrl(format.type, format.quality)
      target: "_blank"

  menu.setItems(items)

v.set "openTrackContextMenu", (source, menu)->
  items = []

  if info = getTrackInfo(source, @tracks, @releases)
    if !info.lost
      items.push
        action: "play"
        name: "Play Song"
        source: source

      items.push
        action: "copy"
        name: "Copy Crediting"
        track: info.track
        release: info.release

    items.push
      action: "remove"
      name: "Remove"
      trackId: info.trackId
      releaseId: info.releaseId

    if !info.lost
      for format, i in formats.defaults
        items.push
          name: format.name
          separated: if i is 0 then true else false
          anchor:
            url: info.track.fileUrl(info.release, format.type, format.quality)
            target: "_blank"

  menu.setItems(items)

v.set "onSelectContextMenu", (item)->
  if item.action is "play"
    @player.play(item.source.getAttribute("index"))
  else if item.action is "copy"
    @openCredits(item.track, item.release)
  else if item.action is "remove"
    @removeTrackById(item.trackId, item.releaseId)

# WARNING Duplicate Code
v.set "openCredits", (track, release)->
  view = new TrackCreditView(text: track.creditText(release.attributes.urls))
  view.render()
  @creditsPresenter.open(view)
  view.focus(100)

v.set "onMouseDownTrack", (e)->
  clearTimeout(@downtimer)
  el = e.currentTarget
  @downtimer = setTimeout =>
    @setMovingTrack(el)
    setTrackPosition(el, e)
  , 500

v.set "onMouseUp", (e)->
  clearTimeout(@downtimer)
  return if not @movingEl

  @reorderMovingTrack()
  @setMovingTrack()

v.set "onMouseMove", (e)->
  return if not el = @movingEl
  setTrackPosition(el, e)

module.exports = v.make()
