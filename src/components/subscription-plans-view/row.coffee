parse = require('parse')
view  = require('view-plugin')

onClick = (e)->
  @pane.el.classList.toggle('hide')

onClickDelete = (e)->
  e.stopPropagation()
  title = @model.get('planId')
  strs = @i18.strings.subscriptionPlans
  return unless window.confirm(strs.destroy.replace('%s', title))
  @model.destroy
    wait: true
    error: (model, res, opts)=>
      @toast(parse.backbone.error(res).message, 'error')
    success: (model, res, opts)=>
      @toast(strs.destroyed.replace('%s', title))

v = bQuery.view()

v.use view
  tagName: 'tr'
  className: 'plan-row'
  template: require('./row-template')

v.ons
  'click [role="destroy-plan"]': onClickDelete
  'click': onClick

v.init (opts={})->
  { @pane } = opts
  onClick.call(@)
  @listenTo(@model, 'change', @render.bind(@))

v.set 'render', ->
  @renderer.render()

module.exports = v.make()