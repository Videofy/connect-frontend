datetime = require('date-time')
objtodom = require('obj-to-dom')
sortutil = require('sort-util')
view     = require('view-plugin')
{ dummyForType } = require('./variable-types')

{
  User,
  Track
} = require('contract-assets')

customtypes = ['user', 'track']

instancemap =
  'user': User
  'track': Track
  'array': Array
  'date': Date

getType = (value)->
  type = typeof value
  for k, v of instancemap
    return k if value instanceof v
  type

inputmap =
  'boolean': 'checkbox'
  'string': 'text'
  'date': 'date'
  'number': 'number'

selectlist = ['user', 'track']
notremoveable = ['title', 'type', 'date']

getSelectObj = (value, type, collections)->
  select =
    tagName: 'select'
    attributes:
      'o-type': type
    children: []

  if type is 'user'
    collections.users.getContractable().forEach (user)->
      name = user.getNameAndRealName()
      select.children.push
        tagName: 'option'
        textContent: name
        value: user.id
        selected: value.connectId is user.id

  if type is 'track'
    collections.tracks.models.forEach (track)->
      select.children.push
        tagName: 'option'
        textContent: track.displayTrackArtistTitle()
        value: track.id
        selected: value.connectId is track.id

  select.children.sort(sortutil.object('stringsInsensitive', 'textContent'))
  select.children.unshift
    tagName: 'option'
    textContent: 'Select One'
    selected: !value.connectId
    disabled: true

  select

getInputObj = (value, collections)->
  type = getType(value)

  if type in selectlist
    return getSelectObj(value, type, collections)

  input =
    tagName: 'input'
    type: inputmap[type]

  if type is 'date'
    input.value = datetime.format('Y-m-d')
  else if type is 'boolean'
    input.checked = value
  else
    input.value = value

  input

fixObj = (obj)->
  for key, prop of obj
    type = getType(prop)
    if type is 'object' and prop.assetType in customtypes
      obj[key] = new instancemap[prop.assetType](prop)
    else if type is 'string' and datetime.isIsoString(prop)
      obj[key] = new Date(prop)
  return obj

getDom = (obj, collections)->
  obj = fixObj(obj)

  table =
    tagName: 'table'
    className: 'ss rows'
    children: [
      tagName: 'tbody'
      children: []
    ]

  Object.keys(obj).forEach (key)->
    input = getInputObj(obj[key], collections)
    input.className = 'ss'
    input.attributes ?= {}
    input.attributes.key = key
    input.attributes.role = 'operator'

    header =
      tagName: 'th'
      textContent: key

    value =
      tagName: 'td'
      children: [input]

    remove =
      tagName: 'td'

    if !(key in notremoveable)
      remove.children = [
        tagName: 'button'
        className: 'ss fake'
        attributes:
          role: 'remove'
          key: key
        children: [
          tagName: 'i'
          className: 'fa fa-trash-o ss cl-danger-hover'
        ]
      ]

    table.children[0].children.push
      tagName: 'tr'
      children: [header, value, remove]

  objtodom(table)

getValue = (el, collections, done)->
  if el.type is 'date'
    return done(null, new Date(el.value))
  else if el.type is 'checkbox'
    return done(null, el.checked)
  else if el.tagName.toLowerCase() is 'select'
    otype = el.getAttribute('o-type')
    if otype is 'user'
      return (new User()).importModel(el.value, done)
    if otype is 'track'
      return (new Track()).importModel(el.value, done)
  done(null, el.value)

onClickAdd = (e)->
  type = @n.getEl('[role="new-type"]').value
  name = @n.getEl('[role="new-name"]')
  key = name.value.toLowerCase().replace(/[\s\W]/g, '_').trim()

  return unless key

  if (@obj[key]?)
    return @toast('That variable already exists.', 'error')

  @obj[key] = dummyForType(type)
  @renderEditor()
  name.value = ''
  @tiger()

onClickRemove = (e)->
  key = e.currentTarget.getAttribute('key')
  delete @obj[key]
  @renderEditor()
  @tiger()

onChangeOperator = (e)->
  el = e.currentTarget
  key = el.getAttribute('key')
  getValue el, @, (err, value)=>
    return @toast(err.message, 'error') if err
    @obj[key] = value
    @tiger(key, @obj[key])

onSetVar = (key, value)->
  @renderEditor()
  @tiger(key, value)

v = bQuery.view()

v.use view
  className: 'neditor'
  template: require('./editor-template')

v.ons
  'click [role="add"]': onClickAdd
  'click [role="remove"]': onClickRemove
  'change [role="operator"]': onChangeOperator

v.init (opts={})->
  { @tracks, @users } = opts
  throw Error('No model provided.') unless @model
  throw Error('No users provided.') unless @users
  throw Error('No tracks provided.') unless @tracks

v.set 'tiger', (key, value)->
  @trigger('changed', key, value)

v.set 'render', ->
  @renderer.locals.mode = 'loading'
  @renderer.render()
  @renderEditor()
  @tracks.toPromise().then =>
    @users.toPromise()
  .then =>
    @renderer.locals.mode = 'view'
    @renderer.render()
    @renderEditor()
    @stopListening(@model)
    @listenTo(@model, 'setvar', onSetVar.bind(@))

v.set 'renderEditor', ->
  @obj = @model.attributes.variables
  dom = getDom(@obj, @)
  el = @n.getEl('[role="editor"]')
  while el.firstChild
    el.removeChild(el.firstChild)
  el.appendChild(dom.el)

module.exports = v.make()
