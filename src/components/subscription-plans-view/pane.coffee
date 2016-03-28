LabelView      = require('label-view')
ListManageView = require('list-manage-view')
view = require('view-plugin')

v = bQuery.view()

v.use view
  tagName: 'tr'
  className: 'plan-pane'
  template: require('./pane-template')
  binder: 'property'

v.init (opts={})->
  { types } = opts
  throw Error("types not provided!") unless types

  fn = (property)=> (view, item, items)=>
    @model.save property, items,
      patch: true
      wait: true
      error: (model, res, opts)=>
        @toast(parse.backbone.error(res).message, 'error')

  strings = @i18.strings.userTypes or {}
  lview = new ListManageView
    items: @model.get('userTypes')
    createView: (item)->
      labelview = new LabelView
      labelview.el.classList.add('cancel-padding')
      labelview.el.textContent = strings[item]
      labelview
    createItem: (value, text)->
      value
    getOptions: ->
      types.map (type)->
        value: type
        text: strings[type] or type
  lview.on 'viewadd', fn('userTypes')
  lview.on 'viewremove', fn('userTypes')
  @list = lview

v.set 'render', ->
  @renderer.render()
  @list.render()
  @n.getEl('[role="types"]').appendChild(@list.el)

module.exports = v.make()
