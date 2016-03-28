SignaturePad  = require('signature_pad')
view          = require('view-plugin')
FileDropper   = require("file-dropper")

ContractSignView = v = bQuery.view()

onClickSign = (e)->
  if @pad.isEmpty()
    return @toast("Missing your signature, please draw it.", 'error')

  if @asAuthor and !@model.hasSignatures()
    return unless window.confirm("No signatures have been assigned. Are you sure you want to continue?")

  phrase = @n.getValue('[role="sign-key"]')
  method = if @asAuthor then 'create' else 'sign'
  @model[method] @user, phrase, @pad.toDataURL({scale: 0.5}), (err)=>
    return @toast(err.message, 'error') if err
    @toast("Contract succesfully signed.", 'success')
    @trigger('signed')
    @user.setSignatureImage @pad.toDataURL(), =>
      @render()

onValidatedUpload = (valid, files)->
  return if !valid or !files?.length
  reader = new FileReader()
  reader.onload = (evt)=>
    @pad.fromDataURL('data:image/png;base64,' + btoa(evt.target.result))
  reader.readAsBinaryString(files[0])

onClickClear = (e)->
  @pad?.clear()

v.use view
  className: 'contract-sign-view'
  template: require('./template')
  locals: -> @

v.ons
  'click [role="sign"]': onClickSign
  'click [role="clear"]': onClickClear

v.init (opts={})->
  { @user, @asAuthor } = opts

  throw Error('A contract model must be provided.') unless @model
  throw Error('A user model must be provided.') unless @user

v.set 'render', ->
  @renderer.render()
  @pad = new SignaturePad(@n.getEl('[role="pad"]'))

  @user.getSignatureImage (err, data)=>
    if data and not err
      @pad.fromDataURL('data:image/png;base64,' + data)

  signatureUpload = new FileDropper
    el: @n.getEl("[role='upload']")
    types: "image/png"
  signatureUpload.on("validated", onValidatedUpload.bind(@))

v.set 'getSignature', ->
  if @asAuthor
    @model.attributes.author
  else
    @model.getSignatureForUser(@user)

module.exports = v.make()