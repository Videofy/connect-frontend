PaneUtil                    = require("pane-util")
PaneView                    = require("pane-view")
sortutil                    = require("sort-util")
UserPageView                = require("user-page-view")
UserRowView                 = require("user-row-view")
view                        = require('view-plugin')
fsr                         = require('collection-fsr-plugin')
fsrRenderRows               = require('fsr-render-rows')
cancel                      = require("input-cancel-plugin")
UserCollection              = require("user-collection")

typesToArray = (obj)->
  Object.keys(obj).map (type)->
    [type, obj[type]]
  .sort (a, b)->
    sortutil.strings(a[1], b[1])

UsersView = v = bQuery.view()

v.use view
  className: 'users-view ss table-fsrv'
  template: require('./template')
  locals: ->
    types: typesToArray(@i18.strings.userTypes)
    filterTypes: @i18.strings.defaults.filterTypes

v.init (opts={})->
  { @label, @user } = opts
  @collection = new UserCollection null, fields: [
    'name',
    'realName',
    'email',
    'type',
    'created',
    'subscriptionModelId',
    'lastSeen']

v.set "open", (needle="")->
  @setFilter(needle)
  @render()

v.set "render", ->
  return if @renderer.locals.mode is 'loading'
  @renderer.locals.mode = 'loading'
  @renderer.locals.canCreate = @permissions.canAccess('user.create')
  @renderer.render()
  @collection.sfetch (err, col)=>
    if err
      @renderer.locals.mode = 'error'
      @renderer.locals.error = err.message
      @renderer.render()
      return
    @renderer.locals.mode = 'view'
    @renderer.render()
    @updateFilters()
    @renderRows()

v.use cancel
  target: '[role="filter"]'
  button: '[role="cancel-filter"]'

v.use fsr
  interceptFilterValue: (el, prop, value)->
    return undefined if value is ''
    value

  renderRows: fsrRenderRows
    createRow: (model, pane)->
      new UserRowView
        evs: @evs
        i18: @i18
        model: model
        permissions: @permissions
        pane: pane
    createPane: (model)->
      new PaneView
        colspan: 7
        body: new UserPageView
          evs: @evs
          i18: @i18
          model: model
          permissions: @permissions

  selectFilter:
    type: (type)-> (userTypes)->
      return true if !type
      return userTypes.indexOf(type) > -1

v.set 'setFilter', (needle)->
  propFilter = fsr.createPropertyFilter(@filters)
  filter = fsr.createFilter(needle, [
    'email'
    'name'
    'created'
    'lastSeen'
    '_id'
  ])

  @filter = (model)->
    return false if not propFilter(model)
    if needle then filter(model) else true

v.set 'setSort', (field, mode)->
  sort =
    type: 'stringsInsensitive'
    field: field or 'lastSeen'
    mode: mode or 'asc'
  sort.type = 'dateStrings' if field is 'lastSeen' or field is 'created'
  sort.type = 'stringsArrayInsensitive' if field is 'type'
  @sort = sort

v.set 'setRange', (start=0, increment=100)->
  @range =
    start: start
    increment: increment

module.exports = v.make()
