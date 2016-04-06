fsr  = require('collection-fsr-plugin')
view = require('view-plugin')
Row  = require('./row-view')
Pane = require('./pane-view')
parse = require('parse')
cancel = require('input-cancel-plugin')

onClickAdd = (e)->
  el = @el.querySelector('[role="new-title"]')

  return unless title = el.value

  collision = _.find @collection.models, (model)->
    model.get("title") is title

  return if collision and !window.confirm('An asset with this title already exists. Are you sure you want to continue?')

  el.value = ""
  @collection.create
    title: title
  ,
    wait: true
    error: (model, res, opts)=>
      @toast(parse.backbone.error(res).message, 'error')
    success: (model, res, opts)=>
      @renderRows()

AssetsView = v = bQuery.view()

v.use view
  className: 'assets-view ss table-fsrv'
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
        i18: @i18
        users: @users
        accounts: @accounts
        evs: @evs
      pane = new Pane(opts)
      opts.pane = pane
      row = new Row(opts)
      row.render()
      pane.render()
      tbody.appendChild(row.el)
      tbody.appendChild(pane.el)

v.use cancel
  target: '[role="filter"]'
  button: '[role="cancel-filter"]'

v.ons
  'click [role="add-asset"]': onClickAdd

v.init (opts={})->
  { @users, @accounts } = opts

v.set 'setFilter', (needle)->
  filter = fsr.createFilter(needle, [
    'title'
    '_id'
  ])
  @filter = (model)=>
    ids = model.get('ids') or []
    return true if ids.indexOf(needle) > -1
    filter(model)

v.set 'setSort', (field='date', mode='desc')->
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
  @renderer.render()
  @renderRows()

module.exports = v.make()
