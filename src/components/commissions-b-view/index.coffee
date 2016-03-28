Capsule = require('./capsule')
empty   = require('./empty-template')
fsr     = require('collection-fsr-plugin')
parse   = require('parse')
Ratio   = require('ratio')
view    = require("view-plugin")

onClickAdd = ->
  r = new Ratio('1/2')
  type = @n.getEl('[role="new-type"]').value
  @collection.create
    type: type
    labelRatio: r
  ,
    wait: true
    error: (model, res, opts)=>
      @toast(parse.backbone.error(res), 'error')
    success: (model, res, opts)=>
      @toast('Commission successfully added.', 'success')

CommissionsView = v = bQuery.view()

v.use view
  className: "track-commissions-view"
  template: require("./template")
  locals: ->
    types: @types

v.use fsr
  renderRows: (opts)->
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
        collection: @collection
        users: @users
        accounts: @accounts
        publishers: @publishers
      capsule = new Capsule(opts)
      tbody.appendChild(capsule.el)

v.ons
  'click [role="add-commission"]': onClickAdd

v.init (opts={})->
  { @users, @accounts, @publishers, @types } = opts
  throw Error('Collection not provided.') unless @collection
  throw Error('Users not provided.') unless @users
  throw Error('Accounts not provided.') unless @accounts
  throw Error('Types not provided.') unless @types

v.set 'setFilter', ->
  @filter = ''

v.set 'setSort', (field='endDate', mode='desc')->
  sort =
    type: 'stringsInsensitive'
    field: field
    mode: mode
  sort.type = 'date' if field is 'startDate' or field is 'endDate'
  @sort = sort

v.set 'setRange', ->
  @range =
    start: 0
    increment: @collection.models.length

v.set "render", ->
  @renderer.render()
  @renderRows()

module.exports = v.make()
