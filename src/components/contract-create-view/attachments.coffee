find     = require('find-target-node')
objtodom = require('obj-to-dom')
view     = require('view-plugin')

onChangeFile = (e)->
  return onClickRemove.call(@, e) if e.currentTarget.files.length is 0
  el = e.currentTarget
  @model.attach(el.getAttribute('name'), el.files[0])

onClickAdd = (e)->
  @num++
  row =
    tagName: 'tr'
    children: [
      tagName: 'td'
      children: [
        tagName: 'input'
        type: 'file'
        name: "attachment_#{@num}"
      ]
    ,
      tagName: 'td'
      children: [
        tagName: 'button'
        className: 'ss fake'
        attributes: {
          role: 'remove'
        }
        children: [
          tagName: 'i'
          className: 'fa fa-trash-o ss cl-danger-hover'
        ]
      ]
    ]
  @n.getEl('tbody').appendChild(objtodom(row).el)

onClickRemove = (e)->
  el = e.currentTarget
  row = find el, (target)->
    target.tagName.toLowerCase() is 'tr'
  @model.detach(row.querySelector('input[type="file"]').getAttribute('name'))
  @n.getEl('tbody').removeChild(row)

v = bQuery.view()

v.ons
  "change input[type='file']": onChangeFile
  "click [role='add']": onClickAdd
  'click [role="remove"]': onClickRemove

v.use view
  className: 'attachments'
  template: require('./attachments-template')

v.init (opts={})->
  @num = 0

v.set 'render', ->
  @renderer.render()

module.exports = v.make()