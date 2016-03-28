fsr  = require 'collection-fsr-plugin'
view = require 'view-plugin'
parse = require 'parse'
Row  = require './row-view'
Pane = require './pane-view'

onClickAdd = (e) ->
  el = @el.querySelector('[role="new-name"]')

  return unless name = el.value

  collision = _.find @collection.models, (model)->
    model.get("name") is name

  if collision
    return @toast('An account with this name already exists', 'error')

  el.value = ""
  @collection.create
    name: name
  ,
    wait: true
    error: (model, res, opts)=>
      @toast(parse.backbone.error(res).message, 'error')
    success: (model, res, opts)=>
      @renderRows()

AccountsView = v = bQuery.view()

v.use view
  className: 'accounts-view ss table-fsrv'
  template: require('./template')

v.use fsr
  renderRows: (opts)->
    tbody = @n.getEl('tbody')

    while tbody.firstChild
      tbody.removeChild(tbody.firstChild)

    models = @collection.getPage(opts)
    models.forEach (model)=>
      opts =
        model: model
        permissions: @permissions
        account: model
        users: @users
        evs: @evs
        i18: @i18
        permissions: @permissions
      pane = new Pane(opts)
      opts.pane = pane
      row = new Row(opts)
      row.render()
      pane.render()
      tbody.appendChild(row.el)
      tbody.appendChild(pane.el)

    true

v.ons
  'click [role="add-account"]': onClickAdd

v.init (opts={})->
  { @users } = opts
  throw Error('Users must be provided') unless @users

v.set 'setFilter', (needle)->
  @filter = fsr.createFilter(needle, [
    'name',
  ])

v.set 'setSort', (field='name', mode='desc')->
  sort =
    type: 'stringsInsensitive'
    field: field
    mode: mode
  sort.type = 'dateStrings' if field is 'date'
  @sort = sort

v.set 'setRange', (start=0, increment=100)->
  @range =
    start: start
    increment: increment

v.set 'render', ->
  @renderer.locals.mode = 'loading'
  @renderer.render()
  @collection.toPromise()
  .then =>
    @renderer.locals.mode = 'view'
    @renderer.locals.canCreate = @permissions.canAccess('account.create')
    @renderer.render()
    @renderRows()

module.exports = v.make()
