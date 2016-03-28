SuperModel    = require("super-model")
formatquality = require("format-quality")
querystring   = require("querystring")

getIndex = (items, track, release)->
  trackId = track.id or track
  releaseId = release.id or release
  items.indexOf _.find items, (item, index, arr)->
    item.trackId is trackId and item.releaseId is releaseId

class PlaylistModel extends SuperModel

  urlRoot: '/api/playlist'

  defaults: ->
    name: "Unsaved Playlist"
    tracks: [] # AKA items

  initialize: (opts={})->
    @tracks = []
    @releases = []

  # Expects a backbone collection of backbone track and release models.
  # This method will grab all tracks from the collection that are
  # in it's model's tracks property and put then in the tracks property.
  grabTracks: (tracks, releases)->
    tracks.toPromise()
    .then =>
      releases.toPromise()
    .then =>
      @tracks = @attributes.tracks.map (item)-> tracks.get(item.trackId)
      @releases = @attributes.tracks.map (item)-> releases.get(item.releaseId)

  getTrackIndexById: (tid, rid)->
    items = @attributes.tracks
    for item, i in items
      return i if item.trackId is tid and item.releaseId is rid
    return -1

  getPlayerItems: ->
    @attributes.tracks.map (item)=>
      track = _.find @tracks, (atrack)-> atrack?.id is item.trackId
      release = _.find @releases, (arelease)-> arelease?.id is item.releaseId
      return {} unless track and release
      source: track.playLink(item.releaseId)
      model: track
      track: track
      release: release

  # Takes in track items, and resets them.
  setItems: (items)->
    @tracks = []
    @releases = []
    @set("tracks", items)

  # Compares if items sets already in playlist. Returns true if same.
  compareItems: (others=[])->
    items = @attributes.tracks

    return false if items.length isnt others.length

    for track, i in items
      return false if items[i].releaseId isnt others[i].releaseId and
        items[i].trackId isnt others[i].trackId

    true

  clearTracks: ->
    @setItems([])

  # Expects a backbone track and release models.
  # Position, a integer, is optional.
  # Mutates the tracks property and the model.
  addTrack: (track, release, position)->
    items = (@attributes.tracks or [])

    return false if getIndex(items, track, release) >= 0

    item =
      trackId: track.id
      releaseId: release.id
      startTime: 0

    if position? and position >= 0
      items.splice(position, 0, item)
    else
      items.push(item)

    @set("tracks", items.slice())
    return true

  # Expects a backbone track model and release model.
  # Mutates the tracks property and the model.
  removeTrack: (track, release)->
    items = (@attributes.tracks or [])
    index = getIndex(items, track, release)

    return false if index < 0

    items.splice(index, 1)
    @set("tracks", items.slice())
    return true

  downloadUrl: (format, quality)->
    query = formatquality(format, quality)
    query.method = 'download'

    str = "?#{querystring.stringify(query)}"
    "#{@url()}/download#{str}"

module.exports = PlaylistModel