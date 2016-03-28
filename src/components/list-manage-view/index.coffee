KeyValueMap = require("key-value-map")
row         = require('./row-template')
view        = require('view-plugin')

onClickAdd = (e)->
  if select = @n.getEl('select')
    option = select.options[select.selectedIndex]
    select.selectedIndex = 0
    return if option.disabled
  else
    option = {}

  item = @createItem(option.value, option.text)
  view = @createView(item)
  view.render()
  @items.push(item)
  @imap.set(view, item)
  @addView(view, true)

onClickRemove = (e)->
  el = e.currentTarget.parentElement.parentElement
  view = @views.get(el)
  throw Error('Unable to get view.') unless view
  @removeView(view)

ListManageView = v = bQuery.view()

v.use view
  className: "list-manage-view"
  template: require('./template')
  locals: ->
    options: if @getOptions then @getOptions() else undefined
    strings:
      selectOne: "Select One"
      add: "Add"

v.ons
  "click [role='add-item']": onClickAdd
  "click [role='remove-item']": onClickRemove

v.init (opts={})->
  { @items, @createView, @createItem, @getOptions } = opts
  @imap = new KeyValueMap
  @views = new KeyValueMap

  if typeof @items is 'function'
    @getItems = @items
    @items = []
  else
    @getItems = => @items

v.set 'render', ->
  @views.clear()
  @renderer.render()
  @items = @getItems() or []
  for item in @items
    view = @createView(item)
    view.render() if view.render
    @imap.set(view, item)
    @addView(view, false)

v.set 'getView', (item)->
  views = @imap.keys
  for view, i in views
    return view if @imap.get(view) is item

v.set 'addView', (view, trigger)->
  tr = document.createElement('tr')
  tr.innerHTML = row()
  tr.querySelector('[role="view"]').appendChild(view.el)
  @el.querySelector('tbody').appendChild(tr)
  @views.set(tr, view)
  @trigger("viewadd", view, @imap.get(view), @items) if trigger

v.set 'removeView', (view)->
  item = @imap.get(view)
  @items.splice(@items.indexOf(item), 1)
  @imap.delete(view)
  tr = view.el.parentElement.parentElement
  tr.parentElement.removeChild(tr)
  view.remove()
  @trigger("viewremove", view, item, @items)

module.exports = v.make()
