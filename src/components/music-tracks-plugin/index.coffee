PlaylistModel = require("playlist-model")
TrackContextMenu = require("track-context-menu-plugin")

find = (el)->
  target = el
  while target
    break if target.getAttribute("track-id") and target.getAttribute("release-id")
    target = target.parentElement
  target

getTrackInfo = (el, tracks, releases)->
  return undefined if not target = find(el)
  track: tracks.get(target.getAttribute("track-id"))
  release: releases.get(target.getAttribute("release-id"))

getTrack = (el, tracks)->
  return undefined if not target = find(el)
  tracks.get(target.getAttribute("track-id"))

makeId = (tid, rid)->
  "#{tid}:#{rid}"

draw = (tracks)->
  txt = "#{tracks.length} Track"

  if tracks.length > 1
    txt += "s"
  else if tracks.length is 1
    txt += " (#{tracks[0].track.attributes.title})"

  cvs = document.createElement("canvas")
  cvs.width = 800
  ctx = cvs.getContext("2d")
  ctx.fillStyle = "black"
  ctx.font = "10pt proxima-nova"
  ctx.textBaseline = "top"
  ctx.fillText(txt, 0 , 0)

  img = document.createElement("img")
  img.src = cvs.toDataURL()
  img

selectKeyDown = (e)->
  return e.metaKey if (navigator.platform == "MacIntel")
  e.ctrlKey

displayX = (classname, check)->
  return if not tracks = @n.getEl("tbody")

  id = undefined
  if check
    item = @player.playlist.get("tracks")[@player.index] or {}
    id = makeId(item.trackId, item.releaseId)

  for tr, i in tracks.children
    iid = makeId(tr.getAttribute("track-id"), tr.getAttribute("release-id"))
    @n.evaluateClass(tr, classname, !!(id and iid is id))

module.exports = (config={})-> (v)->

  v.use TrackContextMenu
    evs: ["click [role='options']", "contextmenu tbody"]
    trackerName: config.trackerName
    findSourceEl: (el)-> find(el)

  v.ons
    "dragstart td[draggable]": "onDragStartTrack"
    "dragend td[draggable]": "onDragEndTrack"
    "dblclick [role='play']": "onClickPlay"
    "click [role='play-mobile']": "onClickPlayMobile"
    "click [role='pause-mobile']": "onClickPauseMobile"
    "click [role='add']": "onClickAdd"
    "click [role='in-playlist']": "onClickInPlaylist"
    "click td": "onClickCell"

  v.init (opts={})->
    if not @getPlaylistItems
      throw Error('The "getPlaylistItems" method does not exist.')

    { @player } = opts
    @releases = opts.releases
    @tracks = opts.tracks
    @user = opts.user
    @selected = []
    @evs.on "changeplaylist", @onChangePlaylist.bind(@)
    @player.on "play", @onChangePlayer.bind(@)
    @player.on "pause", @displayPlaying.bind(@)
    @playlist = new PlaylistModel
    @resetPlayerItems = true
    @on "render", =>
      @displayMarked()
      @displayActive()
      @displayPlaying()

  v.set "playSong", (tid, rid)->
    reset = false
    items = @getPlaylistItems()

    if !@playlist.compareItems(items)
      @playlist.setItems(items)
      reset = true

    @playlist.grabTracks(@tracks, @releases).then =>
      resetPlaylist = @player.playlist isnt @playlist
      @player.set(@playlist.getPlayerItems()) if reset or resetPlaylist

      if resetPlaylist
        @player.playlist = @playlist
        @evs.trigger("changeplaylist")

      # TODO Fix the assumption that the track index will always be available.
      @player.play(@player.playlist.getTrackIndexById(tid, rid))
      @displayActive()
      @displayPlaying()

  v.set "pauseSong", (tid, rid)->
    @player.pause(@playlist.getTrackIndexById(tid, rid))
    @displayActive()
    @displayPlaying()

  v.set "displayActive", ->
    displayX.call(@, 'active', @player.playlist is @playlist)

  v.set "displayPlaying", ->
    displayX.call(@, 'playing', @player.audio and not @player.audio.paused)

  v.set "displayMarked", ->
    return if not @curpl
    return if not tracks = @n.getEl("tbody")
    tks = @curpl.get("tracks").map (item)->
      makeId(item.trackId, item.releaseId)

    for tr, i in tracks.children
      id = makeId(tr.getAttribute("track-id"), tr.getAttribute("release-id"))
      @n.evaluateClass(tr, "added", id in tks)

  v.set "addTrackToCurrentPlaylist", (track, release)->
    if not @curpl
      @curpl = new PlaylistModel
      @evs.trigger("changeplaylist", @curpl)

    playlist = @curpl
    playlist.update() if playlist.addTrack(track, release)
    @evs.trigger("addtracktoplaylist")

  v.set "onDragStartTrack", (e)->
    e = e.originalEvent

    tracks = []
    if @selected.length > 1 and e.target.parentElement.classList.contains("selected")
      for el, i in @selected
        tracks.push(getTrackInfo(el, @tracks, @releases))
    else
      tracks.push(getTrackInfo(e.target, @tracks, @releases))

    return if tracks.length is 0

    tids = tracks.map (item)-> item.track.id
    rids = tracks.map (item)-> item.release.id

    e.dataTransfer.setData("text/track-ids", tids.join(","))
    e.dataTransfer.setData("text/release-ids", rids.join(","))
    e.dataTransfer.setDragImage(draw(tracks), 20, 20)
    @evs.trigger("openplaylist")
    @evs.trigger("dragtracks:start", tracks)
    @isDragging = true

  v.set "onDragEndTrack", (e)->
    return if not @isDragging
    delete @isDragging
    @evs.trigger("dragtracks:end")

  v.set "onCurrentPlaylistTracksChanged", ->
    @displayMarked()

  v.set "onChangePlaylist", (playlist)->
    return if not playlist

    if @curpl
      @stopListening @curpl

    @curpl = playlist
    @listenTo @curpl, "change:tracks", @onCurrentPlaylistTracksChanged.bind(@)
    @displayMarked()
    @displayActive()

  v.set "onChangePlayer", ->
    @displayActive()
    @displayPlaying()

  v.set "onCloseContextMenu", ->
    @preventCellClick = true

  v.set "onClickPlay", (e)->
    info = getTrackInfo(e.target, @tracks, @releases)
    if @player.audio?.paused or @player.playlist isnt @playlist or info.track.id isnt @curtr?.track.id
      @playSong(info.track.id, info.release.id)
      @curtr = info
    else
      @pauseSong(info.track.id, info.release.id)

  v.set "onClickPlayMobile", (e)->
    @onClickPlay(e)

  v.set "onClickPauseMobile", (e)->
    @onClickPlay(e)

  v.set "onClickAdd", (e)->
    return if not info = getTrackInfo(e.target, @tracks, @releases)
    @addTrackToCurrentPlaylist(info.track, info.release)

  v.set "onClickInPlaylist", (e)->
    return if not playlist = @curpl
    return if not info = getTrackInfo(e.target, @tracks, @releases)
    playlist.update() if playlist.removeTrack(info.track, info.release)

  v.set "onClickCell", (e)->
    return if not tracks = @n.getEl("tbody")

    if @preventCellClick
      delete @preventCellClick
      return

    el = e.target.parentElement
    count = 0

    for tr, i in tracks.children
      if tr isnt el
        count++ if tr.classList.contains("selected")
        @n.evaluateClass(tr, "selected", false) if not selectKeyDown(e)

    selected = el.classList.contains("selected")
    selected = false if selected and count > 0
    @n.evaluateClass(el, "selected", !selected)

    @selected.length = 0
    for tr, i in tracks.children
      @selected.push(tr.lastChild) if tr.classList.contains("selected")
