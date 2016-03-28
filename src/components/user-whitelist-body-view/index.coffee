datetime = require("date-time")
view     = require('view-plugin')
rows     = require('./row-template')

onClickToggle = (e)->
  @setFilter(e.target.getAttribute('filter') or 'all')

onModelChange = ->
  @renderRows()

getLogs = (model, filter)->
  if filter is 'active'
    return model.get("whitelistChangeLog").filter (item)-> !item.updated?

  model.get('whitelistChangeLog')

UserWhitelistBodyView = v = bQuery.view()

v.use view
  className: "whitelist-body-view"
  template: require('./template')

v.ons
  "click button[role='toggle']": onClickToggle

v.init (opts={})->
  @type = 'active'
  @listenTo @model, 'change', onModelChange.bind(@)

v.set 'render', ->
  @renderer.locals.mode = 'loading'
  @renderer.render()
  @model.sfetch (err)=>
    if err
      @renderer.locals.mode = 'error'
      @renderer.locals.error = err.message
      @renderer.render()
      return
    @renderer.locals.mode = 'view'
    @renderer.render()
    @renderRows()

v.set 'setFilter', (type)->
  @type = type
  @n.evaluateClass('[filter="active"]', 'selected', type is 'active')
  @n.evaluateClass('[filter="all"]', 'selected', type is 'all')
  @renderRows()

v.set 'renderRows', ->
  @n.getEl('tbody')?.innerHTML = rows
    format: datetime.format
    logs: getLogs(@model, @type)

module.exports = v.make()
