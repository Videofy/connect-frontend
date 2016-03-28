Chart = require('ratio-chart')
Ratio = require('ratio')
view  = require('view-plugin')
parse = require('parse')
fractionize = require('fraction-buttons-plugin')

updateChart = (model, chart)->
  r = model.get('labelRatio')
  chart.set([
    { value: Ratio(r.toString()) }
    { value: Ratio(1).minus(r) }
  ])

onChangeCommission = (e)->
  @n.getEl('[role="percentage"]').textContent = (@model.get('labelRatio').valueOf() * 100).toFixed(2)
  updateChart(@model, @chart)

onChangeRatio = (e)->
  @model.save labelRatio: (new Ratio(e.target.value)).toString(),
    wait: true
    error: (model, res, opts)=>
      @toast(parse.backbone.error(res).message, 'error')

CommissionLabelView = v = bQuery.view()

v.use view
  className: "commission-label-view"
  template: require("./template")
  binder: 'property'

v.use(fractionize())

v.ons
  'change [role="labelRatio"]': onChangeRatio

v.init (opts={})->
  return throw Error('Model must be provided.') unless @model
  @chart = new Chart
    size: 30
    chart:
      showTooltips: false
      animation: false
  @listenTo @model, 'change:labelRatio', onChangeCommission

v.set "render", ->
  @renderer.render()
  @el.querySelector('[role="chart"]').appendChild(@chart.el)
  updateChart(@model, @chart)

module.exports = v.make()
