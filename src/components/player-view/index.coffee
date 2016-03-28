narrow       = require("is-narrow")
Node         = require("node")
PlaylistView = require("playlist-view")
SeekerView   = require("seeker-view")
View         = require("view-plugin")
VolumeView   = require("volume-view")

PlayerView = v = bQuery.view()

v.use View
  className: "player-view"
  template: require("./template")

v.ons
  "click [role='togglePlaylist']": "onClickTogglePlaylist"
  "click [role='play']": "onClickPlay"
  "click [role='next']": "onClickNext"
  "click [role='previous']": "onClickPrevious"
  "click [role='shuffle']": "onClickShuffle"
  "click [role='repeat']": "onClickRepeat"

v.init (opts={})->
  { @player } = opts

  playerChange = @onPlayerChange.bind(@)
  playerStop = @onPlayerPause.bind(@)
  @cbs =
    player:
      change: playerChange
      add: playerChange
      remove: playerChange
      set: playerChange
      play: @onPlayerPlay.bind(@)
      stop: playerStop
      pause: playerStop
      ended: playerStop
    timer:
      step: @onTimerStep.bind(@)

  @seekerView = new SeekerView(player: @player)
  @volume = new VolumeView(player: @player)

  @playlistView = new PlaylistView
    evs: opts.evs
    i18: opts.i18
    player: @player
    tracks: opts.tracks
    releases: opts.releases
    playlists: opts.playlists

  @evs.on "changeplaylist", @onChangePlaylist.bind(@)
  @evs.on "openplaylist", @openPlaylist.bind(@)
  @evs.on "closeplaylist", @closePlaylist.bind(@)
  @evs.on "addtracktoplaylist", @onPlayerAdd.bind(@)

v.set "remove", ->
  Backbone.View.prototype.remove.apply(this, arguments)
  for key, value of @cbs.player
    @player.off(key, value)
  @seekerView.unwatch()
  clearTimeout(@stepTimer)

v.set "delegateEvents", ->
  Backbone.View.prototype.delegateEvents.apply(this, arguments)
  for key, value of @cbs.player
    @player.on(key, value)

v.set "render", ->
  @renderer.locals.narrow = narrow(600)
  @renderer.render()

  @seekerView.render()
  @n.getEl(".seeker").appendChild(@seekerView.el)
  @seekerView.watch()

  @volume.render()
  @n.getEl(".actions.secondary").appendChild(@volume.el)

  @playlistView.render()
  @el.insertBefore(@playlistView.el, @el.firstChild)

  @checkActions()
  @startStepTimer()
  @volume.update(@player.vol)

v.set "cleanEvents", ->
  @player.audio?.removeEventListener "error", @displayBtn
  @player.audio?.removeEventListener "canplay", @onAudioError

v.set "displayBtn", (btn) ->
  return if not @el.firstChild

  if btn is "pause"
    if @player.audio?.readyState < 3
      btn = "loading"
    else
      @cleanEvents()

  @n.evaluateClass("[role='play']", "fa-play", btn is "play")
  @n.evaluateClass("[role='play']", "fa-pause", btn is "pause")
  @n.evaluateClass("[role='play']", "fa-refresh", btn is "loading")
  @n.evaluateClass("[role='play']", "fa-spin", btn is "loading")
  @n.evaluateClass("[role='play']", "fa-exclamation-triangle",
    btn is "error")
  @n.evaluateDisabled("[role='play']",
    btn is "error" or btn is "loading")

v.set "onAudioError", ->
  @evs.trigger "toast",
    text: @i18.strings.player.error
    theme: "error"
    time: 2500
  @displayBtn("error")

v.set "toggle", ->
  @el.classList.toggle("open")
  @evs.trigger("closemenu") if @el.classList.contains("open") and narrow()

v.set "closePlaylist", ->
  @playlistView.el.classList.remove("open")
  @n.getEl("[role='more-controls']")?.classList.remove("open")

v.set "openPlaylist", ->
  @playlistView.el.classList.add("open")
  @n.getEl("[role='more-controls']")?.classList.add("open")
  @evs.trigger("closemenu") if narrow()

v.set "autoOpenPlaylist", ->
  if not @autoOpenedOnPlay and not narrow(600)
    @autoOpenedOnPlay = true
    @openPlaylist()

v.set "togglePlaylist", ->
  @playlistView.el.classList.toggle("open")
  @n.getEl("[role='more-controls']")?.classList.toggle("open")
  @evs.trigger("closemenu") if narrow()

v.set "onClickTogglePlaylist", ->
  @togglePlaylist()

v.set "setTrackDetails", ( model ) ->
  title = model?.get("title") or @i18.strings.player.noTrack
  artists = model?.get("artistsTitle") or @i18.strings.player.noArtist

  playlist = ""
  if playlistName = @player.playlist?.get("name")
    playlistName = "Catalog" if playlistName is "Unsaved Playlist"
    playlist = "Playing from " + playlistName

  @n.setText("[role='artists']", artists)
  @n.setText("[role='trackTitle']", title)
  @n.setText("[role='playlistName']", playlist)
  @n.getEl("[role='artists']").setAttribute("title", artists)
  @n.getEl("[role='trackTitle']").setAttribute("title", title)

v.set "checkActions", ->
  noTracks = @player.items.length is 0
  @n.evaluateDisabled("[role='play']", noTracks)
  @n.evaluateDisabled("[role='next']", noTracks or 
    (@player.getIndex() >= @player.items.length - 1 and not @player.loop))
  @n.evaluateDisabled("[role='previous']", noTracks or 
    (@player.getIndex() is 0 and not @player.loop))
  @n.evaluateDisabled("[role='repeat']", noTracks)
  @n.evaluateDisabled("[role='shuffle']", noTracks)

v.set "startStepTimer", ->
  if @stepTimer
    clearTimeout(@stepTimer)
  @stepTimer = setTimeout(@cbs.timer.step, 500)

v.set "activatePlaylistBtn", (bool)->
  @n.evaluateClass("[role='togglePlaylist']", "active", bool)

v.set "onPlayerPlay", ->
  if @player.audio.readyState < 3
    @displayBtn("loading")
    @player.audio.addEventListener "canplay",
      @displayBtn.bind(@, "pause")
    @player.audio.addEventListener "error", @onAudioError.bind(@)
  else
    @displayBtn("pause")

v.set "onPlayerPause", ->
  @displayBtn("play")

v.set "onPlayerChange", ->
  @setTrackDetails(@player.items[@player.index]?.model)
  @checkActions()

v.set "onPlayerAdd", ->
  @activatePlaylistBtn(true)
  setTimeout(@activatePlaylistBtn.bind(@), 500, false)

v.set "onClickPlay", (e)->
  if not @player.audio or @player.audio.paused
    @player.play()
  else
    @player.pause()

v.set "onClickPrevious", (e)->
  @player.previous()

v.set "onClickNext", (e)->
  @player.next()

v.set "onClickShuffle", (e)->
  @player.shuffle = !@player.shuffle
  @n.evaluateClass("[role='shuffle']", "active", @player.shuffle)
  @evs.trigger("player:mode-changed", @player, "shuffle")

v.set "onClickRepeat", (e)->
  @player.loop = !@player.loop
  @n.evaluateClass("[role='repeat']", "active", @player.loop)
  @evs.trigger("player:mode-changed", @player, "loop")
  @checkActions()

v.set "onChangePlaylist", (playlist)->
  @autoOpenPlaylist() if playlist

v.set "getTime", ( seconds ) ->
  minutes: Math.floor(seconds / 60)
  seconds: ("0" + (Math.floor(seconds % 60))).slice(-2)

v.set "onTimerStep", ->
  if @el.firstChild
    dt = @getTime(@player.audio?.duration or 0)
    ct = @getTime(@player.audio?.currentTime or 0)
    @n.setText("label.seeked", "#{ct.minutes}:#{ct.seconds}")
    @n.setText("label.time", "#{dt.minutes}:#{dt.seconds}")
  @startStepTimer()

module.exports = v.make()
