view  = require('view-plugin')
parse = require('parse')

onClick = (e)->
  @pane.el.classList.toggle('hide')
  @pane.open()

onClickDelete = (e)->
  e.stopPropagation()
  name = @model.get('name')
  id = @model.get('_id')
  text = @i18.strings.defaults.destroyMsg.replace(/\{.+\}/, name)
  return unless confirm(text)
  @model.destroy
    wait: true
    error: (model, res, opts)=>
      @toast(parse.backbone.error(res).message, 'error')
    success: (model, res, opts)=>
      @toast("Account \"#{name}\" was successfully removed.", 'success')

v = bQuery.view()

v.use view
  tagName: 'tr'
  className: 'asset-row-view'
  template: require('./row-template')

v.ons
  'click [role="delete"]': onClickDelete
  'click': onClick

v.init (opts={})->
  { @pane, @model } = opts
  throw Error('Model must be set') unless @model
  throw Error('Pane must be set') unless @pane

  @listenTo(@model, 'change', @render.bind(@))
  @pane.el.classList.add('hide')

v.set 'render', ->
  @renderer.locals.canDelete = @permissions.canAccess('account.destroy')
  @renderer.render()

module.exports = v.make()
