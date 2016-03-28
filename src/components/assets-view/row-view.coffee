view  = require('view-plugin')
parse = require('parse')

onClick = (e)->
  @pane.el.classList.toggle('hide')

onClickDelete = (e)->
  e.stopPropagation()
  title = @model.get('title')
  text = @i18.strings.defaults.destroyMsg.replace(/\{.+\}/, title)
  return unless confirm(text)
  @model.destroy
    wait: true
    error: (model, res, opts)=>
      @toast(parse.backbone.error(res).message, 'error')
    success: (model, res, opts)=>
      @toast("Asset \"#{title}\" was successfully removed.", 'success')

v = bQuery.view()

v.use view
  tagName: 'tr'
  className: 'asset-row-view'
  template: require('./row-template')

v.ons
  'click [role="delete"]': onClickDelete
  'click': onClick

v.init (opts={})->
  { @pane } = opts
  onClick.call(@)
  @listenTo(@model, 'change', @render.bind(@))

v.set 'render', ->
  @renderer.render()

module.exports = v.make()