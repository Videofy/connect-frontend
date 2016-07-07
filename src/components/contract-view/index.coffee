datetime   = require('date-time')
marked     = require('marked')
objtodom   = require('obj-to-dom')
signatures = require('./signatures-template')
SignView   = require('contract-sign-view')
view       = require('view-plugin')
ContractModel = require('contract-model')

ContractView = v = bQuery.view()

v.use view
  className: 'contract-view'
  template: require('./template')

v.init (opts={})->
  { @user } = opts

  throw Error('User is not provided.') unless @user
  throw Error('Collection not provided.') unless @collection

v.set 'open', (id)->
  @contractId = id
  @render()

v.set 'render', ->
  delete @model
  @renderer.locals.mode = 'loading'
  @renderer.render()
  return unless @contractId
  return @renderIt() if @model = @collection.get(@contractId)
  @model = new ContractModel _id: @contractId
  @model.toPromise().then =>
    @collection.add(@model)
    @renderIt()
  .catch (err) =>
    @renderer.locals.mode = 'error'
    @renderer.render()

v.set 'renderIt', ->
  if @model?
    @renderer.locals.mode = 'view'
    @renderer.render()
    @renderBody()
    @renderSignatures()
    @renderSigning()
  else
    @renderer.locals.mode = 'not-found'
    @renderer.render()

v.set 'renderBody', ->
  return unless @model
  @n.getEl('[role="body"]').innerHTML = marked(@model.get('render'))

v.set 'renderSignatures', ->
  return unless @model
  contract = @model.attributes
  obj =
    format: datetime.format.bind(null, "F j, Y")
    signatures: contract.signatures.concat(contract.author)
  @n.getEl('[role="signatures"]').innerHTML = signatures(obj)

v.set 'renderSigning', ->
  return if !@model or !@model.isSignatureNeededByUser(@user)

  @sign = new SignView
    user: @user
    model: @model
    evs: @evs
    i18: @i18
  @sign.render()
  @listenTo(@sign, 'signed', @renderIt.bind(@))
  @n.getEl('[role="signing"]').appendChild(@sign.el)

module.exports = v.make()
