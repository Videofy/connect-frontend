node  = require('node')
parse = require('parse')
row   = require('./row-template')
view  = require('view-plugin')

getIndex = (e)->
  node.getChildIndex(@el.querySelector("tbody"),
    e.currentTarget.parentNode.parentNode)

onInputChange = (e)->
  index = getIndex.call(@, e)
  @model.attributes[@property][index] = e.currentTarget.value
  @save(@model.attributes[@property])

onCreateClick = (e)->
  val = ""
  arr = @model.attributes[@property]
  arr.push(val)
  @add(val, arr.length - 1)
  @save(arr)

onRemoveClick = (e)->
  @remove(getIndex.call(@, e))
  @save(@model.attributes[@property])

InputListView = v = bQuery.view()

v.use view
  className: 'input-list-view'
  template: require('./template')

v.init (opts={})->
  { @property, @type, @placeholder, @disabled } = opts
  @binds = []
  @inputBind = onInputChange.bind(this)
  @removeBind = onRemoveClick.bind(this)
  @model.set(@property, []) unless @model.get(@property)

v.set "render", ->
  @renderer.render()
  @el.querySelector("[role='add']")
    .addEventListener("click", onCreateClick.bind(this))
  for v, i in @model.get(@property)
    @add(v, i)
  @n.evaluateClass(null, "disabled", @disabled)

v.set "save", ( arr )->
  config = {}
  config[@property] = arr
  @model.save config,
    wait: true
    patch: true
    success: ( model, res, opts ) =>
    error: ( model, res, opts ) =>
      err = parse.backbone.error(res)
      msg = err.message
      msg = err.errors[@property].message if err.errors?[@property]?
      @toast(msg, 'error')

v.set "clear", ->
  for v, i in @binds
    @remove(i)
    i--

v.set "add", ( value, index ) ->
  return unless tbody = @n.getEl('tbody')

  el = document.createElement('tr')
  el.innerHTML = row
    type: @type || 'text'
    placeholder: @placeholder || ''
    value: value || ''
    disabled: @disabled || false

  input = el.querySelector('input')
  input.addEventListener('change', @inputBind)
  button = el.querySelector('button')
  button.addEventListener('click', @removeBind)
  tbody.appendChild(el)

  @binds.push
    el: el
    input: input
    btn: button

v.set "remove", ( index ) ->
  item = @binds[index]
  return unless item and tbody = @n.getEl('tbody')

  tbody.removeChild(item.el)
  item.input.removeEventListener("change", @inputBind)
  item.btn.removeEventListener("click", @removeBind)
  @binds.splice(index, 1)
  arr = @model.attributes[@property]
  arr.splice(index, 1)

module.exports = v.make()
