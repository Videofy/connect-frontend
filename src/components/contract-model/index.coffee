assets     = require('contract-assets')
dateutil   = require('date-time')
parse      = require('parse')
request    = require('superagent')
SuperModel = require('super-model')

sample = '# {{title}}\n'+
'{{date}}\n'+
'\n'+
'Type your contract body here.'

validSignature = (sig)->
  return false unless sig.connectId
  return false unless sig.name
  return false unless sig.email
  true

userToSignature = (user)->
  attr = user.attributes
  sig =
    connectId: attr._id
    name: attr.realName
    email: attr.email
  return undefined unless validSignature(sig)
  sig

baseViewUrl = 'contracts/view/:id'

getReturnUrl = ->
  window.location.origin + "/##{baseViewUrl}"

class ContractModel extends SuperModel

  idAttribute: "_id"

  urlRoot: '/api/contract'

  reset: ->
    @clear()
    delete @attachments
    @setup()

  setup: (opts={})->
    title = if opts.title then opts.title else ''
    today = if opts.date instanceof Date then opts.date else new Date()
    years = if opts.years? then opts.years else 10
    @set
      text: opts.text or sample
      variables:
        title: title
        type: ''
        date: today
        years: years
        track: new assets.map.track
      signatures: []
      viewers: []

  clone: (contract)->
    @setup()
    contract = if contract.attributes? then contract.attributes else {}
    @set(_.pick(contract, 'text', 'variables'))

    # Remove specific assetType objects.
    vars = @attributes.variables
    Object.keys(vars).forEach (key)->
      return unless vars[key].assetType and assets.map[vars[key].assetType]
      # Blank out selected objects, but keep them around.
      vars[key] = new assets.map[vars[key].assetType]

  hasSignatures: ->
    return (@attributes.signatures or []).length > 0

  getSignatureForUser: (user, a='connectId', b='_id')->
    arr = @attributes.signatures or []
    _.detect arr, (sig)-> sig[a] is user.attributes[b]

  addSignatureByUser: (user, key='signatures')->
    return -1 if !sig = userToSignature(user)
    @attributes[key].push(sig)
    @attributes[key].length - 1

  removeSignatureByUser: (user, key='signatures')->
    arr = @attributes[key]
    sig = @getSignatureForUser(user)

    return -1 unless sig

    index = arr.indexOf(sig)
    arr.splice(index, 1)
    index

  clearSignatures: (key='signatures')->
    @attributes[key].length = 0

  assignSignaturesFromTrackVariables: (tracks, users)->
    vars = @attributes.variables
    tks = Object.keys(vars)
      .map (key)->
        if vars[key].assetType is 'track'
          return tracks.get(vars[key].connectId)
        undefined
      .filter (item)->
        !!item

    ids = []
    signatures = @get('signatures')
    tks.forEach (model)->
      track = model.attributes
      track.artists.forEach (artist)->
        unless _.find(signatures, (sig)-> sig.connectId is artist.artistId)
          ids.push(artist.artistId)
    ids = _.uniq(ids)
    ids.forEach (id)=>
      return unless user = users.get(id)
      @addSignatureByUser(user)

  attach: (key, file)->
    unless @isNew()
      throw Error('Contract can only have attachments if it is not created.')

    @attachments = @attachments or {}
    @attachments[key] = file

  detach: (key)->
    return unless @attachments
    delete @attachments[key]

  create: (user, phrase, data, done)->
    return done(Error('The contract is not new.')) unless @isNew()

    sig = userToSignature(user)
    sig.signKey = phrase
    sig.imageDataUrl = data

    contract = _.clone(@attributes)
    contract.author = sig

    article =
      trackId: []
      userId: []

    Object.keys(contract.variables).forEach (key)->
      value = contract.variables[key]
      return unless value.assetType
      key = value.assetType + 'Id'
      article[key].push(value.connectId) if article[key]

    req = request.post(@url()).withCredentials()

    req.accept('application/json')
    req.field('article', JSON.stringify(article))
    req.field('contract', JSON.stringify(contract))
    req.field('returnUrl', getReturnUrl())

    attachments = @attachments or {}
    Object.keys(attachments).forEach (key)->
      req.attach(key, attachments[key], attachments[key].name)

    req.end (err, res)=>
      return done(err) if err = parse.superagent(err, res)
      @set(res.body)
      done(undefined, @)

  sign: (user, phrase, data, done)->
    if @isNew()
      throw Error('Contracts which are not created cannot be signed.')

    if not sig = @getSignatureForUser(user)
      return done(Error('User signature not found.'))

    sig.signKey = phrase
    sig.imageDataUrl = data
    sig.copy = @attributes.render
    sig.returnUrl = getReturnUrl()
    request.post(@url() + '/sign')
      .withCredentials()
      .send(sig)
      .end (err, res)=>
        if err = parse.superagent(err, res)
          return done(err)
        @set(res.body)
        done(undefined, @)

  cancel: (done)->
    request.post(@url() + '/cancel')
      .withCredentials()
      .end (err, res)=>
        if err = parse.superagent(err, res)
          return done(err)
        @set(res.body)
        done(undefined, @)

  isCanceled: ->
    !!@attributes.canceled

  isComplete: ->
    return false if @attributes.canceled
    sigs = @attributes.signatures or []
    states = sigs.map (sig)->
      if sig.hash then 1 else 0
    total = _.reduce(states, ((memo, num)-> memo + num), 0)
    total is sigs.length

  isSignatureNeededByUser: (user)->
    sigs = @attributes.signatures or []
    states = sigs.map (sig)->
      if sig.connectId is user.id and not sig.hash then 1 else 0
    total = _.reduce(states, ((memo, num)-> memo + num), 0)
    total > 0

  getViewUrl: ->
    baseViewUrl.replace(':id', @id)

  getPdfUrl: ->
    @url() + "/pdf"

  getAttachmentUrl: (attachment)->
    @url() + "/attachment/#{attachment.name or attachment}"

module.exports = ContractModel
