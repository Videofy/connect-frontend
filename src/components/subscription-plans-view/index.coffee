view  = require('view-plugin')
fsr   = require('collection-fsr-plugin')
sort  = require('sort-util')
Row   = require('./row')
Pane  = require('./pane')
parse = require('parse')
empty = require('./empty-template')

onClickAdd = (e)->
  titleEl = @n.getEl('[role="new-plan-title"]')
  planId = titleEl.value
  collision = _.first @collection.models, (model)->
    model.get("planId") is planId

  strings = @i18.strings.subscriptionPlans
  text = strings.create.replace('%s', planId)
  return if collision.length and not window.confirm(text)

  attr =
    planId: planId
    channelNum: 2
    period: 1
    amount: 100
    labelId: @model.id
  @collection.create attr,
    wait: true
    error: (model, res, opts)=>
      @toast(parse.backbone.error(res).message, 'error')
    success: (model, res, opts)=>
      @toast(strings.created.replace('%s', planId), 'success')
      titleEl.value = ''

SubscriptionPlansView = v = bQuery.view()

v.use view
  className: 'subscription-plans-view'
  template: require('./template')

v.use fsr
  interceptFilterValue: (el, prop, value)->
    return undefined if value is ''
    value *= 1 if prop in ['channelNum', 'period']
    if prop is 'active'
      return el.checked if el.checked
      return undefined
    value

  renderRows: (opts)->
    return false unless tbody = @n.getEl('tbody')

    while tbody.firstChild
      tbody.removeChild(tbody.firstChild)

    models = @collection.getPage(opts)

    if !models.length
      tbody.innerHTML = empty()
      return false

    models.forEach (model)=>
      opts =
        model: model
        permissions: @permissions
        i18: @i18
        users: @users
        evs: @evs
        types: @model.get('userTypes')
      pane = new Pane(opts)
      opts.pane = pane
      row = new Row(opts)
      row.render()
      pane.render()
      tbody.appendChild(row.el)
      tbody.appendChild(pane.el)

    true

v.ons
  'click [role="add-plan"]': onClickAdd

v.init (opts={})->
  throw Error('Model not provided.') unless @model
  throw Error('Collection not provided.') unless @collection

v.set 'setSort', (field='planId', mode='desc')->
  sort =
    type: 'stringsInsensitive'
    field: field
    mode: mode
  sort.type = 'bool' if field is 'active'
  sort.type = 'number' if field in ['channelNum', 'period', 'amount']
  @sort = sort

v.set 'setRange', (start=0, increment=25)->
  @range =
    start: start
    increment: increment

v.set 'setFilter', (needle)->
  if needle
    @filters.planId = (value)->
      rx = new RegExp(".*" + needle + ".*", "i")
      rx.test(value)
  else
    delete @filters.planId

  @filter = fsr.createPropertyFilter(@filters)
  @setRange()

v.set 'render', ->
  @renderer.locals.mode = 'loading'
  @renderer.render()
  @collection.sfetch (err)=>
    @renderer.locals.mode = if err then 'error' else 'view'
    @renderer.locals.error = err.message if err
    @renderer.render()
    return if err
    @updateFilters()
    @renderRows()

module.exports = v.make()
