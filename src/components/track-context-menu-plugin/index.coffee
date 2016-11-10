ContextMenu      = require("context-menu-plugin")
Formats          = require("formats")
PresenterView    = require("presenter-view")
TrackCreditView  = require("track-credit-view")
request          = require("superagent")

# WARNING Duplicate code, refactor.
getTrackInfo = (el, tracks, releases)->
  return undefined if not el
  track: tracks.get(el.getAttribute("track-id"))
  release: releases.get(el.getAttribute("release-id"))

module.exports = (config={})-> (v)->
  v.use ContextMenu
    evs: config.evs
    ev: config.ev

  v.init (opts={})->
    @creditsPresenter = new PresenterView
    @creditsPresenter.el.classList.add("track-credit", "flexi")
    @on "render", => @creditsPresenter.attach()

  v.set "openCopier", (text)->
    view = new TrackCreditView(text:text)
    view.render()
    @creditsPresenter.open(view)
    view.focus(100)

  v.set "openCredits", (track, release)->
    @openCopier(track.creditText(release.attributes.urls))

  v.set "openCreditsForTracks", (tracks)->
    text = ""
    tracks.forEach (item)->
      text += item.track.creditText(item.release.attributes.urls) + "\n\n"
    @openCopier(text)

  v.set "onOpenContextMenu", (source)->
    items = []
    el = if config.findSourceEl then config.findSourceEl(source) else source

    if @selected and @selected.length > 1 and el.classList.contains("selected")
      tracks = []
      for el, i in @selected
        tracks.push(getTrackInfo(el.parentElement, @tracks, @releases))

      items.push
        action: "add-batch"
        name: "Add #{@selected.length} to Playlist"
        tracks: tracks

      items.push
        action: "copy-batch"
        name: "Copy Crediting for #{@selected.length} Tracks"
        tracks: tracks

    else if info = getTrackInfo(el, @tracks, @releases)
      if @playSong
        items.push
          action: 'play'
          name: 'Play Song'
          track: info.track
          release: info.release
          separated: false

      if @addTrackToCurrentPlaylist
        items.push
          action: "add"
          name: "Add to Playlist"
          track: info.track
          release: info.release
          separated: false

      items.push
        action: "copy"
        name: "Copy Crediting"
        separated: false
        track: info.track
        release: info.release

      if info.track.attributes.downloadable
        for format, i in Formats.defaults
          items.push
            action: "download"
            name: format.name
            separated: if i is 0 then true else false
            format: format
            track: info.track
            release: info.release
            anchor:
              url: info.track.fileUrl(info.release, format.type, format.quality)
              download: "#{info.track.get("artistsTitle")} - #{info.track.get("title")}.#{format.type}"
              target: "_blank"

    @contextMenu.setItems(items)

  v.set "onSelectContextMenu", (item)->
    if item.action is "copy"
      @openCredits(item.track, item.release)
    else if item.action is "add"
      @addTrackToCurrentPlaylist(item.track, item.release)
    else if item.action is "play"
      @playSong(item.track.id, item.release.id)
    else if item.action is "add-batch"
      for track, i in item.tracks
        @addTrackToCurrentPlaylist(track.track, track.release)
    else if item.action is "copy-batch"
      @openCreditsForTracks(item.tracks)
    else if item.action is "download"
      @evs.trigger("download", item)