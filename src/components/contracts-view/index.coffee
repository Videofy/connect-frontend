fsr  = require('collection-fsr-plugin')
view = require('view-plugin')

onClickCancel = (e)->
  id = e.currentTarget.getAttribute('contract-id')
  return unless contract = @collection.get(id)
  return unless window.confirm("Are you sure you want to cancel the contract \"#{contract.get('variables').title}\"?")

  contract.cancel (err, contract)=>
    return @toast(err.message, 'error') if err
    @toast('Contract succesfully canceled.')
    @renderRows()

ContractsView = v = bQuery.view()

v.use view
  className: 'contracts-view ss table-fsrv'
  template: require('./template')

v.use fsr
  rowsTemplate: require('./rows-template')

v.ons
  'click [role="cancel"]': onClickCancel

v.set 'setFilter', (needle)->
  @filter = fsr.createFilter(needle, [
    'variables.title',
    'variables.type',
    'author.name',
    'author.email'
  ])

v.set 'setSort', (field='variables.date', mode='desc')->
  sort =
    type: 'stringsInsensitive'
    field: field
    mode: mode
  sort.type = 'dateStrings' if field is 'variables.date'

  if field is 'status'
    sort.field = (a, b)->
      ac = a.isComplete()
      bc = b.isComplete()
      return -1 if ac < bc
      return 1 if ac > bc
      0

  @sort = sort

v.set 'setRange', (start=0, increment=100)->
  @range =
    start: start
    increment: increment

v.set 'render', ->
  @renderer.render()
  @renderRows()

module.exports = v.make()
