Review         = require('./review')
template       = require('./text-template')
view           = require('view-plugin')
sort           = require('sort-util')
parse          = require('parse')
populateSelect = require('populate-select')
varTypes       = require('./variable-types')

onKeyUp = (e)->
  clearTimeout(@timer) if @timer
  callback = =>
    @model.set('text', @n.getValue('textarea'))
    @renderPreview()
  @timer = setTimeout(callback, 250)
  @updateHeight()

onClickSave = (e)->
  title = @n.getValue('[role="save-template-name"]')
  text = @n.getValue('textarea')
  model = _.detect @collection.models, (model)->
    model.get('title') is title
  error = (model, res, opts)=>
    @toast(parse.backbone(res).message, 'error')
  success = (model, res, opts)=>
    @toast('The template "'+title+'" was saved.', 'success')

  if model and window.confirm('Are you sure you want to overwrite the existing template?')
    return model.save text: text,
      patch: true
      error: error
      success: success
  else if model
    return

  vars = _.clone(@model.attributes.variables)
  for k, v of vars
    vars[k] = varTypes.getType(v)

  attr =
    title: title
    text: text
    variables: vars
  @collection.create attr,
    wait: true
    error: error
    success: success

onClickLoad = (e)->
  return unless id = @el.querySelector('[role="templates-list"]').value
  t = @collection.get(id)
  if t
    @n.getEl('textarea').value = t.get('text')
    @updateHeight()
    onKeyUp.call(@, e)
    @n.getEl('[role="save-template-name"]').value = t.get('title')
    vars = @model.attributes.variables
    unless vars.type
      vars.type = t.get('title')
    if not vars.title and vars.track?.title
      vars.title = vars.type + ' for ' + vars.track.title
    for k, v of t.attributes.variables
      unless vars[k]
        vars[k] = varTypes.dummyForType(v)

    @model.trigger('setvar')
  else
    window.alert('The template was not found. This was an error that should not have happened. Tell Thomas.')

onSubmitForm = (e)->
  form = e.currentTarget
  form.elements['text'].value = @model.get('text')
  form.elements['variables'].value = JSON.stringify(@model.get('variables'))
  return true

v = bQuery.view()

v.use view
  className: 'edit-n-review ss padded'

v.ons
  'keyup textarea': onKeyUp
  'click [role="save-template"]': onClickSave
  'click [role="load-template"]': onClickLoad
  'submit form': onSubmitForm

v.init (opts={})->
  throw Error('Model not provided.') unless @model
  throw Error('Collection not provided.') unless @collection
  @review = new Review(opts)
  @listenTo(@collection, 'add reset remove', @renderSelect.bind(@))

v.set 'render', ->
  @el.innerHTML = template()
  div = @el.firstChild
  div.insertBefore(@review.el, div.firstChild)
  @renderSelect()
  @trigger('render')
  @renderPreview()

v.set 'renderSelect', ->
  return unless sel = @n.getEl('[role="templates-list"]')
  @collection.toPromise().then =>
    return unless @collection.length
    while sel.firstChild
      sel.removeChild(sel.firstChild)
    populateSelect sel, @collection.models, (model)->
      textContent: model.get('title')
      value: model.id

v.set 'renderPreview', ->
  @review.renderText(@model.attributes.text, @model.attributes.variables)

v.set 'updateHeight', ->
  el = @el
  a = @n.getEl('textarea')
  aph = a.getBoundingClientRect().height
  eph = parseInt(el.style.height) or el.getBoundingClientRect().height
  a.style.height = '1px'
  a.style.height = a.scrollHeight + 'px'
  anh = a.getBoundingClientRect().height
  el.style.height = (eph - aph) + anh + 'px'

module.exports = v.make()
