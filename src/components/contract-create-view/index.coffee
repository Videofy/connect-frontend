ContractModel = require('contract-model')
TrackCollection = require('track-collection')
UserCollection  = require('user-collection')
mkCrudCol     = require('crud-collection')
dateutil      = require('date-time')
Editor        = require('./editor')
Signatures    = require('./signatures'
SignView      = require('contract-sign-view'))
Text          = require('./text')
view          = require('view-plugin')

TemplateCollection = mkCrudCol
  baseUri: 'contract-template'

onSigned = ->
  model = new ContractModel(@model.attributes)
  @router.navigate(model.getViewUrl(), trigger: true)
  @model.reset()
  @render()

onChangedEditor = (key, value)->
  @renderPreview()
  return unless value?.assetType is 'track'
  @model.assignSignaturesFromTrackVariables(@tracks, @users)
  @signatures.render()

ContractCreateView = v = bQuery.view()

v.init (opts={})->
  { @user, @router } = opts

  throw Error('Author user model must be provided.') unless @user
  throw Error('No router provided.') unless @router

  @users = new UserCollection null, fields: ['name', 'realName', 'type', 'email']
  @tracks = new TrackCollection null, fields: ['title', 'artistsTitle', 'artists']
  @model = new ContractModel
  @model.setup()

  @signatures = new Signatures _.extend _.clone(opts),
    model: @model
    users: @users
    user: @user

  @text = new Text _.extend _.clone(opts),
    model: @model
    collection: new TemplateCollection

  @editor = new Editor _.extend _.clone(opts),
    model: @model
    users: @users
    tracks: @tracks
    obj: @model.attributes.variables

  @sign = new SignView _.extend _.clone(opts),
    model: @model
    user: @user
    asAuthor: true

  @listenTo(@sign, 'signed', onSigned.bind(@))
  @listenTo(@editor, 'changed', onChangedEditor.bind(@))

v.use view
  className: 'contract-create-view'
  template: require('./template')

v.set 'open', (needle)->
  return unless needle != @toclone
  @toclone = needle
  @model.reset() if not needle
  @render(true)

v.set 'render', (force)->
  @renderer.locals.mode = 'loading'
  @renderer.render()

  return @renderIt(force) unless @toclone

  clone = new ContractModel(_id: @toclone)
  clone.sfetch (err, model)=>
    if err
      @toast('Could not clone desired contract. Creating new contract.', 'error')
    else
      @model.clone(model)
    @renderIt(force)

v.set 'renderIt', (force)->
  @renderer.locals.mode = 'view'
  @renderer.render()

  if not @renderedSigner or force
    @renderedSigner = true
    @sign.render()

  @signatures.render(force)
  @text.render(force)
  @editor.render(force)
  @el.querySelector('[role="editor"]').appendChild(@text.el)
  @el.querySelector('[role="vars"]').appendChild(@editor.el)
  @el.querySelector('[role="sigs"]').appendChild(@signatures.el)
  @el.querySelector('[role="sign"]').appendChild(@sign.el)

v.set 'renderPreview', ->
  @text.renderPreview()

module.exports = v.make()
