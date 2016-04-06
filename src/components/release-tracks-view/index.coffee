parse  = require('parse')
player = require('private-player-plugin')
rows   = require('./rows-template')
sort   = require('sort-util')
view   = require('view-plugin')
dt     = require('date-time')
TrackCollection = require('track-collection')

sortTitle = sort.model.bind(null, 'stringsInsensitive', 'title')

syncPreReleaseDate = ->
  dateString = @model.get('preReleaseDate')
  prevDate = if dateString then new Date(dateString) else null
  date = @model.calculatePreReleaseDate(@mytracks.models)
  return unless date and not prevDate or not date and prevDate or
    date?.getTime() != prevDate?.getTime()

  if confirm(@i18.strings.releases.updatePreReleaseMsg)
    @model.updatePreReleaseDate(date)

getTracks = (release, collection)->
  collection.models.concat().sort (a, b)->
    pa = a.getPosition(release)
    pb = b.getPosition(release)
    return -1 if pa < pb
    return 1 if pa > pb
    0

getTrack = (target, collection)->
  while !id and target
    id = target.getAttribute('track-id')
    target = target.parentElement
  collection.get(id)

onClickAdd = (e)->
  select = @n.getEl('[role="select-track"]')
  id = select.options[select.selectedIndex].value
  return unless track = @tracks.get(id)
  track.setPosition @model, @mytracks.models.length + 1, (err, model)=>
      return @toast(err.message, 'error') if err
      @mytracks.add(model)
      select.selectedIndex = 0
      @renderRows()

onClickRemove = (e)->
  track = getTrack(e.currentTarget, @mytracks)
  track.removeFromRelease @model, (err, model)=>
      return @toast(err.message, 'error') if err
      @mytracks.remove(model)
      @renderRows()

onChangePosition = (e)->
  position = parseInt(e.currentTarget.value)
  return unless track = getTrack(e.currentTarget, @mytracks)
  track.setPosition @model, position, (err)=>
      return @toast(err.message, 'error') if err
      @renderRows()

onClickTogglePredate = (e)->
  target = e.currentTarget
  enabled = target.checked
  input = target.parentElement.querySelector('input[type="date"]')
  date = if enabled then new Date(@model.get('releaseDate')) else ''
  track = @mytracks.get(target.getAttribute('track-id'))
  track.setPreReleaseDate @model.id, date, (err)=>
    if err
      target.checked = !target.checked
      return @toast(err.message, 'error')
    input.classList[if enabled then 'remove' else 'add']('hide')
    input.value = dt.format('Y-m-d', date) if date
    syncPreReleaseDate.call(@)

onChangePredate = (e)->
  target = e.currentTarget
  date = new Date(target.value.replace('-', '/'))
  track = @mytracks.get(target.getAttribute('track-id'))
  track.setPreReleaseDate @model.id, date, (err)=>
    return @toast(err.message, 'error') if err
    syncPreReleaseDate.call(@)

onChangeFree = (e)->
  target = e.currentTarget
  track = @mytracks.get(target.getAttribute('track-id'))
  track.setReleaseInfo @model, isFree: !!target.checked, (err)=>
    @toast(err.message, 'error') if err

ReleaseTracksView = v = bQuery.view()

v.ons
  'click [role="add-track"]': onClickAdd
  'click [role="remove-track"]': onClickRemove
  'change [role="track-position"]': onChangePosition
  'click [role="toggle-predate"]': onClickTogglePredate
  'change [role="predate"]': onChangePredate
  'change [role="isfree"]': onChangeFree

v.use player
  ev: 'click [role="play-track"]'
  getTrack: (el)-> getTrack(el, @mytracks)

v.use view
  className: 'release-tracks-view'
  template: require('./template')
  locals: ->
    tracks: @tracks.models.concat().sort(sortTitle)

v.init (opts={})->
  { @tracks, @player } = opts

  throw Error('Model must be provided.') unless @model
  throw Error('Tracks collection must be provided.') unless @tracks

  @mytracks = new TrackCollection null,
    by:
      key: 'albums.albumId',
      value: @model.id
    fields: [
      'title',
      'artistsTitle',
      'albums']

v.set 'render', ->
  @renderer.locals.mode = 'loading'
  @renderer.render()
  @tracks.toPromise().then =>
    @mytracks.sfetch (err, col)=>
      if err
        @renderer.locals.mode = 'error'
        @renderer.locals.error = err.message
        return
      @renderer.locals.mode = 'view'
      @renderer.render()
      @renderRows()

v.set 'renderRows', ->
  @n.getEl('tbody').innerHTML = rows
    release: @model
    tracks: getTracks(@model, @mytracks)
    format: dt.format

module.exports = v.make()
