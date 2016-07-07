parse         = require('parse')
querystring   = require('querystring')
formatquality = require('format-quality')
request       = require('superagent')
sort          = require('sort-util')
SuperModel    = require('super-model')
matcher       = require('value-matcher-util')
eurl          = require('end-point').url

class ReleaseModel extends SuperModel

  urlRoot: "/api/release"

  coverUrl: (size, label)->
    art = @get('coverArt')
    ratio = if window.devicePixelRatio > 1 then 2 else 1
    thumbHashes = @get('thumbHashes')
    label ?= 'monstercat'

    if @isArtOnS3() and thumbHashes
      size = ratio * size if size
      h = if size and thumbHashes?[size] then thumbHashes[size] else @get('imageHashSum')
      url = "https://s3.amazonaws.com/data.monstercat.com/blobs/#{h}"
    else if not art or art is 'bestof2011.png'
      retina = if ratio is 2 then "@2x" else ""
      if size is 32
        url = "/img/defaultArtSmall#{ retina }.png" if size is 32
      else
        url = "/img/defaultArt#{ retina }.png"
    else
      url = "#{@url()}/cover/#{ art }"
      url += "?t=#{ ratio * size }" if size
    url

  isArtOnS3: ->
    !!@get('thumbHashes')

  hasArt: ->
    @get('coverArt') or @isArtOnS3()

  displayTitle: ->
    "#{ @get('renderedArtists') } - #{ @get('title') }"

  # Gets the current or last available download package.
  getLatestPackage: (packages)->
    mine = packages.models
    .filter (pack)=>
      pack.get('releaseId') is @id
    .sort (a, b)->
      sort.dateStrings(a.get('createdDate'), b.get('createdDate'))
    mine[0]

  calculatePreReleaseDate: (tracks)->
    return null unless tracks
    datedTracks = tracks.filter (track)=>
      !!track.getPreReleaseDate(@id)
    sorted = _.sortBy datedTracks, (track)=>
      new Date(track.getPreReleaseDate(@id)).getTime()
    if sorted.length then new Date(sorted[0].getPreReleaseDate(@id)) else null

  updatePreReleaseDate: (date, done)->
    done ?= ->
    @save preReleaseDate: date,
      patch: true
      wait: true
      error: (model, res, opts)=>
        done(parse.backbone.error(res), @)
      success: (model, res, opts)=>
        done(null, @)

  getErrors: (done)->
    warnings = []

    map =
      imageHashSum: [undefined, '']
      releaseDate: undefined
      renderedArtists: [undefined, '']
      title: [undefined, '']
      upc: [undefined, '']

    details =
      imageHashSum:
        field: "imageHashSum"
        message: "Cover Art must be supplied."
      releaseDate:
        field: "releaseDate"
        message: "A release date must be specified."
      renderedArtists:
        field: "renderedArtists"
        message: "A release requires a rendered artist."
      title:
        field: "title"
        message: "A title is required."
      upc:
        field: "upc"
        message: "A UPC is required."
      urls:
        field: "urls"
        message: "A soundcloud link is required for the release to appear on the monstercat.com site."

    Object.keys(map).forEach (key) =>
      if matcher.valsMatch(map, @attributes, key)
        warnings.push(details[key])

    unless _.detect(@get('urls') or [], (url)-> url.match(/soundcloud/i))
      warnings.push(details.urls)

    done(null, warnings)
    @trigger('geterrors', warnings)

  package: (done)->
    request
      .post(eurl("/api/package/release/#{@id}"))
      .withCredentials()
      .end (err, res)->
        done(parse.superagent(err, res), res)

  packageUrl: (format, quality, packageId)->
    query = formatquality(format, quality)

    str = "?#{querystring.stringify(query)}"

    if not packageId
      return "#{@url()}/download#{str}"

    eurl("/album/package/#{packageId}#{str}")

  isReleased: ->
    return no if @get('showToAdminsOnly')

    releaseDate = new Date(@get('releaseDate'))
    preReleaseDate = if @get('preReleaseDate') then new Date(@get('preReleaseDate')) else null
    tomorrow = new Date()
    tomorrow.setHours(48, 0, 0, 0)
    tomorrow >= releaseDate

    (preReleaseDate and tomorrow > preReleaseDate) or tomorrow > releaseDate

  isTrackReleased: (track)->
    releaseDate = new Date(@get('releaseDate'))
    preReleaseDate = if @get('preReleaseDate') then new Date(@get('preReleaseDate')) else null
    tomorrow = new Date()
    tomorrow.setHours(48, 0, 0, 0)

    return yes if not preReleaseDate or tomorrow > releaseDate

    track.get('albums').some (trackAlbum)=>
      return no if trackAlbum.albumId isnt @id or not trackAlbum.preReleaseDate
      tomorrow > new Date(trackAlbum.preReleaseDate)

module.exports = ReleaseModel
