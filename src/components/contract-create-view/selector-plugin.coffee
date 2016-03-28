objtodom = require('obj-to-dom')
make     = require('./create-selector')

module.exports = (config={})->

  onClickAddTo = (e)->
    el = e.currentTarget
    key = el.getAttribute('add-to')
    sel = @n.getEl("[selection-for='#{key}']")
    id = sel.value

    return unless item = config.addItem.call(@, key, id)

    list = @n.getEl("[selection-items='#{key}']")
    list.appendChild(objtodom(make.row(item, key)).el)
    @trigger 'addeditem'
    if config.resetToFirst
      sel.selectedIndex = 0

  onClickRemoveFrom = (e)->
    el = e.currentTarget
    key = el.getAttribute('remove-from')
    id = el.getAttribute('identifier')
    list = @n.getEl("[selection-items='#{key}']")

    index = config.removeItem.call(@, key, id)
    return unless index > -1
    list.removeChild(list.children[index])
    @trigger 'removeditem'

  (v)->
    v.ons
      'click [add-to]': onClickAddTo
      'click [remove-from]': onClickRemoveFrom
