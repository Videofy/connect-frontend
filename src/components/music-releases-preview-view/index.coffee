DateTime         = require("date-time")
Formats          = require("formats")
mobile           = require("is-mobile")
MusicTracks      = require("music-tracks-plugin")
PlaylistModel    = require("playlist-model")
PresenterView    = require("presenter-view")
releasemenu      = require("release-context-menu-plugin")
request          = require("superagent")
view             = require("view-plugin")

{ formatDateTime } = require("music-tracks-table-plugin")

generatePlaylistTracks = (tracks=[], releaseId)->
  tracks.map (item)->
    trackId: item.id
    releaseId: releaseId

getRelease = (id, releases, tracks)->
  return undefined if not release = releases.get(id)

  rls = _.clone(release.attributes)
  rls.date = new Date(rls.releaseDate)
  rls.date.format = formatDateTime

  rtracks = []
  genres = []

  tracks.forEach (item)=>
    ids = item.attributes.albums.map (album)-> album.albumId
    if rls._id in ids and release.isTrackReleased(item)
      tk = _.clone(item.attributes)
      tk.id = tk._id
      tk.trackNumber = (_.find item.attributes.albums, (album)-> album.albumId is rls._id).trackNumber
      rtracks.push(tk)
      genres = genres.concat(tk.genre, tk.genres)

  genres = _.unique(genres.filter (item)-> !!item)
  rls.genres = genres

  rls.tracks = rtracks.sort (a, b)->
    return -1 if a.trackNumber < b.trackNumber
    return 1 if a.trackNumber > b.trackNumber
    0

  rls

onClickArt = ->
  img = new Image()
  img.src = @getArtLink()
  @presenter.open(img)

MusicReleasesPreviewView = v = bQuery.view()

v.use view
  className: "music-releases-preview-view"
  template: require("./template")

v.use MusicTracks
  trackerName: "MusicReleasesPreviewView"

v.use releasemenu
  ev: "click [role='download']"
  from: "MusicReleasesPreviewView"
  getRelease: (source)->
    @releases.get(@releaseId)

v.ons
  "click [role='open-art']": onClickArt
  "click [role='close']": "close"

v.init (opts={})->
  @presenter = new PresenterView
  @presenter.el.classList.add("flexi", "art-preview")

v.set "render", ->
  @releases.toPromise()
  .then => @tracks.toPromise()
  .then =>
    @renderer.locals.release = getRelease.call(@, @releaseId, @releases, @tracks) or {}
    @renderer.locals.art = @getArtLink(256)
    @renderer.locals.isMobile = mobile()
    @renderer.render()
    @playFirst() if @playOnRender

v.set "getPlaylistItems", ->
  generatePlaylistTracks(@renderer.locals.release.tracks,
      @renderer.locals.release._id)

v.set "open", ->
  @el.classList.add("open")
  @presenter.attach()

v.set "close", ->
  @el.classList.remove("open")
  @presenter.dettach()

v.set "isOpen", ->
  @el.classList.contains("open")

v.set "playFirst", (@playOnRender=false)->
  return if @playOnRender
  el = @el.querySelectorAll(".tracks > table tr")[0]
  @onClickPlay(target: el)
  @playOnRender = false

v.set "set", (@releaseId)->
  @render()

v.set "getArtLink", (size)->
  return '' unless @releaseId
  return "/img/defaultArt@2x.png" unless release = @releases.get(@releaseId)
  release.coverUrl(size)

module.exports = v.make()