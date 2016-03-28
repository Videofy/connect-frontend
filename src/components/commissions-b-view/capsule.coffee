CommissionView = require('commission-b-view')
node           = require('node')
row            = require('./capsule-template')
parse          = require('parse')

capitalize = (string)->
  string.charAt(0).toUpperCase() + string.slice(1);

onChange = ->
  @row.innerHTML = row
    model: @model
    capitalize: capitalize

onClick = (e)->
  return onClickDelete.call(@, e) if node.findParent(e.target, '[role="delete-commission"]')
  return onClickClone.call(@, e) if node.findParent(e.target, '[role="clone-as"]')
  @pane.classList.toggle('hide')

onClickClone = (e)->
  e.stopPropagation()
  return unless el = e.currentTarget.querySelector('[as-type]')
  type = el.getAttribute('as-type')
  return unless window.confirm('Are you sure you want to create a '+type+' commission?')
  cln = @model.cloneAs(type)
  @collection.create cln.attributes,
    wait: true
    error: (model, res, opts)=>
      @cv.toast(parse.backbone.error(res).message, 'error')
    success: (model, res, opts)=>
      @cv.toast('Commission successfully cloned.', 'success')

onClickDelete = (e)->
  e.stopPropagation()
  return unless window.confirm('Are you sure you want to remove this commission?')
  @model.destroy
    wait: true
    error: (model, res, opts)=>
      @cv.toast(parse.backbone.error(res).message, 'error')
    success: (model, res, opts)=>
      @cv.toast('Commission succesfully marked as deleted.', 'success')

class Capsule
  constructor: (opts={})->
    { @collection } = opts
    copts = _.clone(opts)
    copts.tagName = 'td'
    @model = opts.model
    @el = document.createDocumentFragment()
    @cv = new CommissionView(copts)
    @cv.el.setAttribute('colspan', 6)
    @row = document.createElement('tr')
    @pane = document.createElement('tr')
    @pane.classList.add('hide')
    @el.appendChild(@row)
    @el.appendChild(@pane)
    onChange.call(@)
    @cv.render()
    @pane.appendChild(@cv.el)
    @model.on 'change', onChange.bind(@)
    @row.addEventListener('click', onClick.bind(@))

module.exports = Capsule
