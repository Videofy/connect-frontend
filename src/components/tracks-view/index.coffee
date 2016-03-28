debug                       = require('debug')('tracks-view')
parse                       = require('parse')
PaneUtil                    = require("pane-util")
PaneView                    = require("pane-view")
Ratio                       = require("ratio")
sortutil                    = require("sort-util")
TrackPageView               = require("track-page-view")
TrackRowView                = require("track-row-view")
view                        = require("view-plugin")
fsr                         = require("collection-fsr-plugin")
fsrRenderRows               = require("fsr-render-rows")
cancel                      = require("input-cancel-plugin")
TrackCollection             = require('track-collection')
PublisherCollection         = require('publisher-collection')
UserCollection              = require('user-collection')
AccountCollection           = require('account-collection')

sel =
  filter: "[role='filter']"
  more: "[role='more']"
  results: "[role='results-count']"
  trackInput: "[role='track-title']"

onClickAdd = (e)->
  el = @el.querySelector(sel.trackInput)

  return unless title = el.value

  collision = _.find @collection.models, (model)->
    model.get("title") is title

  return if collision and !window.confirm(@i18.strings.tracks.confirmTitle)

  el.value = ""
  commissions = @label.get("commissions")
  @collection.create
    title: title
    catalogs: ['gold', 'license', 'sync']
  ,
    wait: true
    error: (model, res, opts)=>
      @toast(parse.backbone.error(res).message, 'error')
    success: (model, res, opts)=>
      # @listing.openView("pane", model)

TracksView = v = bQuery.view()

v.use view
  className: "tracks-view ss table-fsrv"
  template: require("./template")

v.use cancel
  target: '[role="filter"]'
  button: '[role="cancel-filter"]'

v.ons
  "click [role='add-track']": onClickAdd

v.init (opts={})->
  { @label, @transfers } = opts
  @ap = opts.privatePlayer
  @collection = new TrackCollection null, fields: [
    'title',
    'artistsTitle',
    'created',
    'isrc',
    'fileName',
    'hasErrors',
    'catalogs']
  @publishers = new PublisherCollection null,
    by:
      key: 'label'
      value: @label.id
    fields: ['name', 'email', 'contact']
  @users = new UserCollection null, fields: [
    'name',
    'realName',
    'type',
    'email']
  @accounts = new AccountCollection null, fields: [
    'name',
    'users']

v.set "open", (needle="")->
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
    @renderer.locals.canCreate = @permissions.canAccess('track.create')
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
        colspan: 9
        body: new TrackPageView
          model: model
          evs: @evs
          collection: @collection
          permissions: @permissions
          i18: @i18
          label: @label
          publishers: @publishers
          tracks: @collection
          users: @users
          accounts: @accounts
    createRow: (model, pane)->
      new TrackRowView
        evs: @evs
        i18: @i18
        label: @label
        model: model
        permissions: @permissions
        player: @ap
        transfers: @transfers
        pane: pane
        canDelete: @permissions.canAccess('track.destroy')

v.set 'setFilter', (needle='')->
  filter = fsr.createFilter(needle, [
    'title'
    'artistsTitle'
    'created'
    'isrc'
    '_id'
  ])
  @filter = (model)=>
    catalogs = model.get('catalogs')
    if catalogs and @filters.catalogs
      val = false
      for c, i in catalogs
        val = true if @filters.catalogs(c)
      return false unless val
    if needle then filter(model) else true

v.set 'setSort', (field, mode)->
  sort =
    type: 'stringsInsensitive'
    field: field or 'created'
    mode: mode or 'asc'

  sort.type = 'dateStrings' if field is 'created'

  @sort = sort

v.set 'setRange', (start=0, increment=100)->
  @range =
    start: start
    increment: increment

module.exports = v.make()
