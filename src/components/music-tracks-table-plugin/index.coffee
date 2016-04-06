DateTime         = require("date-time")
hms              = require("hms")
musicTracks      = require("music-tracks-plugin")
mobile           = require("is-mobile")
PlaylistModel    = require("playlist-model")
Regex            = require("regex")
sortutil         = require("sort-util")

formatDateTime = (format="M j, Y")->
  DateTime.format(format, @)

formatDuration = (ms)->
  d = hms(ms)
  if d[0] is 0
    d = d.slice(1)
  d.map((n, index)->
    return n if index is 0
    return if n < 10 then "0" + n else n
  ).join(":")

generatePlaylistTracks = (tracks=[])->
  tracks.map (item)->
    trackId: item.id
    releaseId: item.queryables.rid

getTrackGenres = (track)->
  genres = (track.attributes.genres or []).concat(track.attributes.genre)
  genres = genres.filter (item) -> !!item
  genres = _.uniq(genres)
  genres

getGenreColor = (track, label)->
  trackGenre = track.get("genre") ? track.get("genres")?[0] ? "Default"
  match = label.get("genres").filter (genre) ->
    genre.name == trackGenre
  return match[0]?.color

getTracks = (user, releases, tracks, label, filter)->
  arr = []
  tracks
  .filter (track)->
    if user.attributes.hideNonLicensableTracks and not track.attributes.licensable
      return false
    return false unless user.canAccessTrack(track)
    true
  .forEach (track)->
    rids = track.get("albums").map (item)-> item.albumId
    rids.forEach (id) ->
      release = releases.get(id)
      return if not release or (filter and not filter(release, track))
      date = new Date(release.attributes.releaseDate)
      date.format = formatDateTime
      rinfo = track.getReleaseInfo(release)
      trackNumber = rinfo.trackNumber
      predate = new Date(rinfo.preReleaseDate)
      predate.format = formatDateTime
      genres = getTrackGenres(track)
      duration = formatDuration(track.attributes.duration * 1000)
      arr.push
        id: track.id
        title: track.attributes.title
        release: release.attributes.title
        trackNumber: trackNumber
        artists: release.attributes.renderedArtists
        genre: track.attributes.genre
        genres: genres
        genreColor: getGenreColor(track, label)
        date: date
        predate: predate
        track: track
        duration: duration
        bpm: Math.round(track.attributes.bpm) || undefined
        licensable: track.attributes.licensable
        links: release.attributes.links
        released: release.isReleased() and release.isTrackReleased(track)
        queryables:
          rid: release.id
          tid: track.id
          artists: release.attributes.renderedArtists
          genres: genres.join(", ")
          date: date.format()
          duration: track.attributes.duration
          bpm: Math.round(track.attributes.bpm)
          release: release.attributes.title
          title: track.attributes.title
  arr

getNeedles = (needle)->
  needles = []
  return needles if not needle

  # Extract dates out to prevent conflicting commas.
  regex = /[a-z]+\s\d{1,2}[,]\s\d{4}/gim
  dates = needle.match(regex)
  if dates
    for date in dates
      needle = needle.replace(regex, "")
      rex = RegExp(Regex.escapeString(date), "i")
      rex.isDate = true
      needles.push(rex)

  # Set up the rest.
  split = needle.split(",")
  for n, i in split
    value = n.trim()
    if value
      needles.push(RegExp(Regex.escapeString(value), "i"))

  needles

filter = (arr, needle)->
  needles = getNeedles(needle)
  return arr if needles.length is 0
  arr.filter (track)->
    results = needles.length
    for rx in needles
      passone = false
      for k, v of track.queryables
        continue if !rx.isDate and k is 'date'
        passone = true if rx.test(v)
      results-- if not passone
    return false if results is 0
    true

alph = (a, b)->
  a = a.toLowerCase()
  b = b.toLowerCase()
  return 1 if a > b
  return -1 if a < b
  0

alphDesc = (a, b)->
  alph(a, b) * -1

num = (a, b)->
  a = if isNaN(a) then 0 else parseInt(a)
  b = if isNaN(b) then 0 else parseInt(b)
  return 1 if a > b
  return -1 if a < b
  0

numDesc = (a, b)->
  num(a, b) * -1

sortDate = (a, b)->
  sortutil.dates(new Date(parseInt(a)), new Date(parseInt(b)))

sortDateDesc = (a, b)->
  sortDate(a, b) * -1

buckets =
  asc:
    date:
      key: (item)-> String(item.date.getTime())
      sort: sortDate
    release:
      key: (item)-> item.release
      sort: alph
    number:
      key: (item)-> item.trackNumber
      sort: num
    track:
      key: (item)-> item.title
      sort: alph
    artists:
      key: (item)-> item.queryables.artists
      sort: alph
    genres:
      key: (item)-> item.queryables.genres
      sort: alph
    duration:
      key: (item)-> item.queryables.duration
      sort: num
    bpm:
      key: (item)-> item.queryables.bpm
      sort: num
  desc:
    date:
      key: (item)-> String(item.date.getTime())
      sort: sortDateDesc
    release:
      key: (item)-> item.release
      sort: alphDesc
    number:
      key: (item)-> item.trackNumber
      sort: numDesc
    track:
      key: (item)-> item.title
      sort: alphDesc
    artists:
      key: (item)-> item.queryables.artists
      sort: alphDesc
    genres:
      key: (item)-> item.queryables.genres
      sort: alphDesc
    duration:
      key: (item)-> item.queryables.duration
      sort: numDesc
    bpm:
      key: (item)-> item.queryables.bpm
      sort: numDesc

sortTracks = (tracks, bkts, sort='asc')->
  arr = bkts.map (key)-> buckets[sort][key]
  sortutil.bucket(tracks, arr);

getIndexOfAtt = (obj, att, search)->
  return obj.get(att).indexOf(search)

onClickSortHeading = (e)->
  active = @n.getEl('.sort-active[sort]')
  target = e.target

  while target
    break if target.getAttribute('sort')
    target = target.parentElement

  oldOrder = active?.getAttribute('order')
  oldKey = active?.getAttribute('sort')
  newKey = target?.getAttribute('sort')

  if newKey is oldKey and oldOrder is 'desc'
    newKey = undefined
    newOrder = undefined
  else
    newOrder = if oldKey is newKey and oldOrder is 'asc' then 'desc' else 'asc'

  @sort = @getSort(oldKey, newKey, newOrder)
  @sortKey = newKey
  @sortOrder = newOrder

  clearTimeout(@stimer) if @stimer
  @stimer = setTimeout(@render.bind(@), 100)

onClickDisabledTrack = ->
  alert("This track is not available to use for licensing. For more information, please refer to the Licensing page in the Handbook.")

MusicTracksTablePlugin = (config={})-> (v)->

  v.use musicTracks
    trackerName: config.trackerName

  v.init (opts={})->
    { @label, @user } = opts
    @getSort = config.getSort or -> []
    @sort = @getSort()
    @page =
      index: 0
      start: 0
      increment: 100

  v.ons
    "click th[sort]": onClickSortHeading
    "click [role='disabled-track']": onClickDisabledTrack

  v.set "render", ->
    { renderer, page } = @
    renderer.locals.mode = 'loading'

    @releases.toPromise()
    .then => @tracks.toPromise()
    .then =>
      page.results = tracks = sortTracks(filter(@getTracks(), @needle),
        @sort, @sortOrder)
      renderer.locals.mode = 'ready'
      renderer.locals.tracks = tracks.slice(page.start,
        page.start + page.increment)
      renderer.locals.showLicenseInfo = getIndexOfAtt(@user,
        "type", "admin") isnt -1 or
        getIndexOfAtt(@user, "type", "licensee") isnt -1
      renderer.locals.mobile = mobile()
      renderer.render()

      # Rerender the sorting...
      if @sortKey and el = @n.getEl("[sort='#{@sortKey}']")
        el.classList.add('sort-active')
        el.classList.add(@sortOrder)
        el.setAttribute('order', @sortOrder)

  v.set "filter", (@needle)->
    @setPage(0)

  v.set 'setPage', (index)->
    index = 0 if (index < 0)
    @page.index = index
    @page.start = index * @page.increment
    @render()

  v.set 'canPageBackward', ->
    @page.start >= @page.increment and @page.results?.length

  v.set 'canPageForward', ->
    @page.start + @page.increment < @page.results?.length

  v.set "getTracks", ->
    if not @cache
      @cache = getTracks(@user, @releases, @tracks, @label, config.filter)
    @cache

  v.set "getPlaylistItems", ->
    generatePlaylistTracks(@page.results)

ex = module.exports = MusicTracksTablePlugin
ex.formatDateTime = formatDateTime
ex.generatePlaylistTracks = generatePlaylistTracks
ex.filter = filter
