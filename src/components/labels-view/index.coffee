fsr                       = require("collection-fsr-plugin")
fsrRenderRows             = require("fsr-render-rows")
LabelPageView             = require("label-page-view")
LabelRowView              = require("label-row-view")
PaneView                  = require("pane-view")
view                      = require("view-plugin")
cancel                    = require("input-cancel-plugin")

LabelsView = v = bQuery.view()

v.use view
  className: "labels-view ss table-fsrv"
  template: require("./template")

v.ons
  "click [role='add']": "onClickAddNewLabel"

v.init (opts={})->
  { @i18, @dataSources, @permissions } = opts

v.set "render", ->
  @collection.toPromise().then =>
    @renderer.render()
    @updateFilters()
    @renderRows()

v.use cancel
  target: '[role="filter"]'
  button: '[role="cancel-filter"]'

v.use fsr
  renderRows: fsrRenderRows
    createRow: (model, pane)->
      new LabelRowView
        evs: @evs
        i18: @i18
        model: model
        permissions: @permissions
        pane: pane
    createPane: (model)->
      new PaneView
        colspan: 2
        body: new LabelPageView
          evs: @evs
          i18: @i18
          dataSources: @dataSources
          model: model
          permissions: @permissions

v.set 'setFilter', (needle)->
  @filter = fsr.createFilter(needle, [
    'name'
  ])

v.set 'setSort', (field='name', mode='desc')->
  sort =
    type: 'stringsInsensitive'
    field: field
    mode: mode
  @sort = sort

v.set 'setRange', (start=0, increment=100)->
  @range =
    start: start
    increment: increment

v.set "onClickAddNewLabel", (e)->
  name = @el.querySelector("[role='label-title']").value
  return if !name

  @collection.create name: name,
    wait: true
    error: (model, res)=>
      @evs.trigger "toast",
        time: 2500,
        text: JSON.parse(res.responseText).message
        theme: "error"

module.exports = v.make()
