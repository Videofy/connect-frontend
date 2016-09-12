datetime                    = require("date-time")
view                        = require('view-plugin')
WhitelistRowView            = require("user-whitelist-row-view")
fsr                         = require("collection-fsr-plugin")
fsrRenderRows               = require("fsr-render-rows")
UserWhitelistBodyView = v = bQuery.view()

sel =
  vendor: '[name="grant-vendor"]'
  identity: '[name="grant-identity"]'

onGrantVendorChange = (e)->
  e.stopPropagation()
  vendor = @$(sel.vendor).val()
  idEl = @$(sel.identity)
  idEl.attr("placeholder", idEl.attr(vendor + '-placeholder'))

onClickGrant = (e)->
  e.stopPropagation()
  params =
    vendor: @$(sel.vendor).val()
    identity: @$(sel.identity).val()
    userId: @model.get('_id')
    paidInFull: true
    amountRemaining: 0
    whitelisted: true

  # TODO: This should be in the user model, which uses its own internal whitelist collection
  # TODO: Some security and permission checks are probably required... somewhere
  model = @whitelists.create params, 
    wait: true
    error: (model, res, opts)=>
      @toast(parse.backbone.error(res).message, 'error')
    success: (model, res, opts)=>
      @toast('New whitelisted channel added', 'success')
      @render()

v.use view
  template: require('./template')

v.init (opts={})->
  { @subscription } = opts
  @whitelists = @model.getWhitelists()
  @collection = @whitelists

v.use fsr
  renderRows: fsrRenderRows
    empty: ()->
      '<tr><td colspan="6">No whitelists found for this user.</td></tr>'
    createRow: (model, pane)->
      new WhitelistRowView
        evs: @evs
        i18: @i18
        label: @label
        model: model
        packages: @packages
        permissions: @permissions
        sse: @sse
        pane: pane

v.set 'setFilter', (needle='')->
  propFilter = fsr.createPropertyFilter(@filters)
  filter = fsr.createFilter(needle, [
    'identity'
    '_id'
  ])

  @filter = (model)->
    return false if not propFilter(model)
    if needle then filter(model) else true

v.set 'setSort', (field, mode)->
  sort =
    type: 'stringsInsensitive'
    field: field or 'identity'
    mode: mode or 'asc'
  @sort = sort


v.set 'setRange', (start=0, increment=100)->
  @range =
    start: start
    increment: increment

v.set 'render', ->
  @renderer.locals.mode = 'loading'
  @renderer.locals.whitelists = @whitelists
  @renderer.locals.fmtdt = datetime
  @renderer.render()

  renderError = (err)=>
    @renderer.locals.mode = 'error'
    @renderer.locals.error = err.message
    @renderer.render()

  @model.sfetch (err)=>
    return renderError(err) if err
    @whitelists.sfetch (err, list)=>
      return renderError(err) if err
      @renderer.locals.whitelists = @whitelists
      @renderer.locals.mode = 'view'
      @renderer.render()

v.on "change " + sel.vendor, onGrantVendorChange
v.on "click [role='grant-whitelist']", onClickGrant

module.exports = v.make()
