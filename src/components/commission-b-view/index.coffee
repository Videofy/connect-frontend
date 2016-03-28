mkCrudCollection = require('crud-collection')
LabelView = require('commission-label-view')
UsersView = require('commission-users-view')
MechanicalRatesView = require('./rates-view')
view      = require("view-plugin")

RatesCollection = mkCrudCollection
  baseUri: 'commission-rate'

CommissionView = v = bQuery.view()

v.use view
  className: "commission-view"

v.init (opts={})->
  throw Error('Model not provided!') unless @model
  opts = _.omit(opts, 'tagName')
  @label = new LabelView(opts)
  @users = new UsersView(opts)

  return unless @model.type is 'publishing'

  mopts = _.clone(opts)
  mopts.collection = new RatesCollection null,
    by:
      key: 'commissionId'
      value: @model.id
  @mech = new MechanicalRatesView(mopts)

v.set "render", ->
  @label.render()
  @users.render()
  @el.appendChild(@label.el)
  @el.appendChild(@users.el)

  if @mech?
    @mech.render()
    @el.appendChild(@mech.el)

module.exports = v.make()
