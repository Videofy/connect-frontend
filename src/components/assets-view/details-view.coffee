InputListView  = require('input-list-view')
view           = require('view-plugin')

v = bQuery.view()

v.use view
  className: 'asset-details-view'
  template: require('./details-template')
  binder: 'property'

v.init (opts={})->
  @idsList = new InputListView
    disabled: false
    model: @model
    placeholder: ''
    property: 'ids'
    type: 'text'

v.set 'render', ->
  @renderer.render()
  @idsList.render()
  @n.getEl('[role="ids-list"]').appendChild(@idsList.el)

module.exports = v.make()