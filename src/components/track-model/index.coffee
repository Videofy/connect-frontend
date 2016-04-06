debug                = require('debug')('connect:track-model')
parse                = require('parse')
querystring          = require('querystring')
formatquality        = require('format-quality')
request              = require('superagent')
SuperModel           = require('super-model')
purl                 = require('url').parse

getApp = (url)->
  b = purl(url).hostname.split('.')
  b[b.length - 2] or ''

getId = (obj)->
  if obj.id then obj.id else obj

saveCatalogs = (catalogs, done)->
  @save catalogs: _.uniq(catalogs),
    patch: true
    error: (model, res, opts)=>
      done?(parse.backbone.error(res), @)
    success: (model, res, opts)=>
      done?(null, @, catalogs)

class Track extends SuperModel

  idAttribute: "_id"

  urlRoot: '/api/track'

  getErrors: (done)->
    return done(Error('Model has not been saved to the server.')) if @isNew()
    request
      .get("#{@url()}/errors")
      .end (err, res)=>
        done(parse.superagent(err, res), res?.body?.errors or [])

  featuringJoined: ->
    _.chain(@get('featuring') or [])
     .map((feat) -> feat.name or "Unknown")
     .value()
     .join(" & ") or "<no featured artists>"

  @joinedArtists: (xs) ->
    _(xs).pluck("name").join(", ")

  joinedArtists: ->
    if @attributes.artists
      arr = @attributes.artists.map ( artist ) ->
        artist.name
      return arr.join(", ")
    ""

  joinedRemixers: ->
    if @attributes.remixers
      arr = @attributes.remixers.map ( artist ) ->
        artist.name
      return arr.join(", ")
    ""

  joinedGenres: ->
    if @attributes.genres
      return @attributes.genres.join(", ")
    ""

  joinedTags: ->
    if @attributes.tags
      return @attributes.tags.join(", ")
    ""

  releaseDate: -> @formatDate()

  @getAlbum: (release, albums=[])->
    id = getId(release)
    _.detect albums, (album)->
      album.albumId is id

  getPosition: (release)->
    return -1 unless release = @getReleaseInfo(release)
    release.trackNumber

  setPosition: (release, position, done)->
    @setReleaseInfo(release, trackNumber: position, done)

  removeFromRelease: (ro, done)->
    releases = @get('albums')
    release = Track.getAlbum(ro, releases)
    if release
      index = releases.indexOf(release)
      releases.splice(index, 1) if index >= 0
      return @simpleSave(albums: releases, done) if done?
      return @set('albums', releases)
    return done(Error('Release not found.')) if done?

  setReleaseInfo: (ro, obj, done)->
    releases = @get('albums') or []
    release = Track.getAlbum(ro, releases)
    if !release
      release = {albumId: getId(ro)}
      releases.push(release)
    _.extend(release, _.omit(obj, "_id"))
    return @simpleSave(albums: releases, done) if done?
    @set('albums', releases)

  getReleaseInfo: (ro)->
    Track.getAlbum(ro, @get('albums'))

  uploadUrl: ->
    @fileOriginalUrl()

  fileOriginalUrl: ->
    "#{@url()}/wav"

  fileUrl: (release, format, quality, method)->
    throw Error("You must provide a release.") unless release
    throw Error("You must provide an audio format.") unless format

    method = "download" if method isnt "stream"
    release = release.id if "string" isnt typeof release

    query = formatquality(format, quality)
    query.method = method
    query.track = @id

    "/api/release/#{release}/download?#{querystring.stringify(query)}"

  playLink: (release)->
    entry = _.find @attributes.albums, (release)->
      release.albumId is release
    return @fileUrl(release, 'mp3', 128, 'stream') unless entry?
    "https://s3.amazonaws.com/data.monstercat.com/blobs/#{entry.streamHash}"

  displayTitle: ->
    "#{@get('artistsTitle')} - #{@get('title')}"

  displayTrackArtistTitle: ->
    "#{@get('title')} - #{@get('artistsTitle')}"

  creditText: (urls) ->
    title = @displayTitle()
    youtube = _.find urls, (url)-> getApp(url) is 'youtube'
    itunes = _.find urls, (url)-> getApp(url) is 'apple'
    spotify = _.find urls, (url)-> getApp(url) is 'spotify'

    info = "Title: #{title}\n"
    info += "iTunes Download Link: #{itunes}\n" if itunes?
    info += "Listen on Spotify: #{spotify}\n" if spotify?
    info += "Video Link: #{youtube}\n" if youtube?
    return info

  toJSON: (opts)->
    obj = SuperModel.prototype.toJSON.call(@, opts)
    if obj.genres and obj.genres.length >=1
      obj.genre = obj.genres[0]
    else
      obj.genre = ""
    obj

  onCatalog: (type)->
    (@attributes.catalogs or []).indexOf(type) >= 0

  addCatalog: (type, done)->
    catalogs = (@attributes.catalogs or []).concat()
    catalogs.push(type)
    saveCatalogs.call(@, catalogs, done)

  removeCatalog: (type, done)->
    catalogs = (@attributes.catalogs or []).concat()
    catalogs.splice(catalogs.indexOf(type), 1)
    saveCatalogs.call(@, catalogs, done)

  getPreReleaseDate: (rid)->
    album = _.find @attributes.albums, (album)->
      album.albumId is rid
    return undefined unless album
    return album.preReleaseDate or undefined

  setPreReleaseDate: (rid, date, done)->
    album = _.find @attributes.albums, (album)->
      album.albumId is rid
    return done(Error('Specified release not found.')) unless album
    album.preReleaseDate = date
    @save albums: @attributes.albums,
      patch: true
      error: (model, res, opts)=>
        done?(parse.backbone.error(res), @)
      success: (model, res, opts)=>
        done?(null, @)

  generateIsrc: (done) ->
    done ?= ->
    request
    .patch "#{@url()}/generate-isrc"
    .end (err, res)=>
      if err = parse.superagent(err, res)
        done(err)
      else
        @set(_.pick(res.body, 'isrc', 'parsedISRC'))
        done(null, @)

module.exports = Track
