parse = require('parse')
rows  = require('./rows-template')
view  = require('view-plugin')

getId = (target)->
  while !id and target
    id = target.getAttribute('publisher')
    target = target.parentElement
  id

onClickAdd = (e)->
  return unless name = @n.getEl('[role="publisher-name"]').value
  @collection.create name: name,
    wait: true
    error: (model, res, opts)=>
      @toast parse.backbone.error(res).message, 'error'
    success: (model, res, opts)=>
      @render()

onChange = (e)->
  el = e.currentTarget
  property = el.getAttribute('property')
  model = @collection.get(getId(el))
  obj = {}
  obj[property] = el.value
  model.save obj,
    patch: true,
    error: (model, res, opts)=>
      @toast parse.backbone.error(res).message, 'error'

PublishersView = v = bQuery.view()

v.use view
  className: 'publishers-view'
  template: require('./template')

v.ons
  'click [role="add-publisher"]': onClickAdd
  'change [role="property"]': onChange

v.set 'render', ->
  @renderer.locals.mode = 'loading'
  @renderer.render()
  @collection.toPromise().then =>
    @renderer.locals.mode = 'view'
    @renderer.render()
    @renderRows()

v.set 'renderRows', ->
  @n.getEl('tbody').innerHTML = rows
    collection: @collection

module.exports = v.make()