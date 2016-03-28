PaneUtil                    = require("pane-util")
parse                       = require('parse')
PaneView                    = require("pane-view")
ReleasePageView             = require('release-page-view')
ReleaseRowView              = require("release-row-view")
sortutil                    = require("sort-util")
View                        = require("view-plugin")
fsr                         = require("collection-fsr-plugin")
fsrRenderRows               = require("fsr-render-rows")
cancel                      = require("input-cancel-plugin")
TrackCollection             = require('track-collection')
ReleaseCollection           = require('release-collection')

onClickAdd = (e)->
  el = @el.querySelector("[role='release-title']")
  return unless title = el.value

  el.value = ""
  model = @collection.create
    title: title
    label: @label.id
    type: "Single"
    showToAdminsOnly: yes
    showOnWebsite: no
  ,
    wait: true
    error: (model, res, opts)=>
      @toast parse.backbone.error(res).message, 'error'

ReleasesView = v = bQuery.view()

v.use View
  className: "releases-view ss table-fsrv"
  template: require("./template")

v.use cancel
  target: '[role="filter"]'
  button: '[role="cancel-filter"]'

v.ons
  "click [role='add']": onClickAdd

v.init (opts)->
  { @label, @scrollTarget, @privatePlayer } = opts

  @collection = new ReleaseCollection null, fields: [
    'title',
    'renderedArtists',
    'type',
    'catalogId',
    'releaseDate',
    'coverArt',
    'thumbHashes',
    'dirty']

  @tracks = new TrackCollection null, fields: [
    'title',
    'artistsTitle',
    'albums']

v.set 'open', (needle)->
  @setFilter(needle)
  @render()

v.set "render", ->
  return if @renderer.locals.mode is 'loading'
  @renderer.locals.mode = 'loading'
  @renderer.render()
  @collection.sfetch (err, col)=>
    if err
      @renderer.locals.mode = 'error'
      @renderer.locals.error = err.message
      @renderer.render()
      return
    @renderer.locals.mode = 'view'
    @renderer.locals.canCreate = @permissions.canAccess('release.create')
    @renderer.render()
    @updateFilters()
    @renderRows()

v.use fsr
  interceptFilterValue: (el, prop, value)->
    return undefined if value is ''
    value

  renderRows: fsrRenderRows
    createPane: (model)->
      new PaneView
        colspan: 8
        body: new ReleasePageView
          collection: @collection
          evs: @evs
          i18: @i18
          label: @label
          model: model
          permissions: @permissions
          player: @privatePlayer
          sse: @sse
          tracks: @tracks
    createRow: (model, pane)->
      starget = @el.querySelector('.ss.pane-table')?.parentElement
      new ReleaseRowView
        evs: @evs
        i18: @i18
        label: @label
        model: model
        packages: @packages
        permissions: @permissions
        scrollTarget: starget
        sse: @sse
        pane: pane

v.set 'setFilter', (needle='')->
  propFilter = fsr.createPropertyFilter(@filters)
  filter = fsr.createFilter(needle, [
    'title'
    'type'
    'catalogId'
    'releaseDate'
    'renderedArtists'
    '_id'
  ])

  @filter = (model)->
    return false if not propFilter(model)
    if needle then filter(model) else true

v.set 'setSort', (field, mode)->
  sort =
    type: 'stringsInsensitive'
    field: field or 'releaseDate'
    mode: mode or 'asc'
  sort.type = 'dateStrings' if field is 'releaseDate'
  @sort = sort

v.set 'setRange', (start=0, increment=100)->
  @range =
    start: start
    increment: increment

module.exports = v.make()
