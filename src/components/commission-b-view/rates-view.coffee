fsr       = require('collection-fsr-plugin')
view      = require('view-plugin')
countries = require('countries')
RowView   = require('./rate-row-view')
empty     = require('./rates-empty')
parse     = require('parse')

onClickAdd = (e)->
  country = @n.getEl('[role="new-country"]').value
  effect = @n.getEl('[role="new-effect"]').value
  ratio = @n.getValue('[role="new-rate"]')

  return unless ratio

  attr =
    commissionId: @model.id
    country: country
    rateRatio: ratio
    effect: effect

  @collection.create attr,
    wait: true
    error: (model, res, opts)=>
      @toast(parse.backbone.error(res).message, 'error')
    success: (model, res, opts)=>
      @toast("The effect was successfully added.", 'success')

v = bQuery.view()

v.use view
  className: 'mechanical-rates-view'
  template: require('./rates-template')
  locals:
    countries: countries

v.use fsr
  renderRows: (opts={})->
    tbody = @n.getEl('tbody')
    while tbody.firstChild
      tbody.removeChild(tbody.firstChild)

    if !@collection.models.length
      tbody.innerHTML = empty()
      return

    @collection.models.forEach (model)=>
      opts =
        evs: @evs
        model: model
        i18: @i18
        permissions: @permissions
      view = new RowView(opts)
      view.render()
      tbody.appendChild(view.el)

v.ons
  'click [role="add-effect"]': onClickAdd

v.init (opts={})->
  throw Error('Model not provided.') unless @model
  throw Error('Collection not provided.') unless @collection

v.set 'setFilter', ->
  @filter = ''

v.set 'setSort', ->
  @sort =
    type: 'stringsInsensitive'
    field: 'country'
    mode: 'desc'

v.set 'setRange', ->
  @range =
    start: 0
    increment: @collection.models.length

v.set 'render', ->
  @renderer.render()
  @renderRows()

module.exports = v.make()
