eurl                        = require('end-point').url
parse                       = require('parse')
request                     = require('superagent')
SuperModel                  = require("super-model")
WhitelistCollection         = require('whitelist-collection')
WhitelistModel              = require('whitelist-model')
{ downloadBinaryToBase64 }  = require('binary-downloader')
debug                       = require('debug')('mc-connect:user-model')


requiredFields =
  all: [
    'realName'
    'location'
  ]
  artist:[
    'name'
  ]
  payPal: [
    'paypalEmail'
  ]
  contractable: [
    'name'
    'realName'
    'location'
  ]


class UserModel extends SuperModel

  urlRoot: '/api/user'

  signatureUrl: ->
    eurl("#{@url()}/signature")

  impersonateUrl: ->
    url = @url() + '/impersonate?returnUrl=' + encodeURIComponent("#{location.protocol}//#{location.host}")

  initialize: (params, opts)->
    return unless params
    #@setUpChannels(params)

  addWhitelist: (params, done)->
    params.userId = @id
    whitelist = new WhitelistModel(params).save (err, obj)->

  updateWhitelist: ->
    debug('updateWhitelist is deprecated')
    params = { whitelist: @get 'whitelist' }
    @setUpChannels(params)
    @youtubeCollection.reset @ytChannels
    @twitchCollection.reset @twitchChannels
    @trigger 'updatedWhitelist'

  setUpChannels: (params)->
    debug('setUpChannels is depcrcated')
    return no
    @whitelist = @getWhitelist(params)
    @ytChannels = getWhitelist(@whitelist, 'youtube')
    @twitchChannels = getWhitelist(@whitelist, 'twitch')

  getWhitelists: ->
    if !@whitelistCollection
      @whitelistCollection = new WhitelistCollection null,
        by:
          key: 'userId'
          value: @id
    @whitelistCollection

  getWhitelistDEP: (params)->
    debug('this is old news')
    @whitelist = _.map params.whitelist, (item)=>
      item.userId = @id
      return item

  getWhitelistIdentities: ( type, separator ) ->
    arr = @get("whitelist")
    if type
      arr = arr.filter ( item ) ->
        item.name.toLowerCase() is type
    arr = arr.map ( item ) ->
      item.identity

    return arr.join(separator) if separator
    arr

  isWhitelisted: ->
    debug('isWhitelisted deprecated')
    whitelist = @get('whitelist') or []
    flag = true
    whitelist.forEach (item)->
      flag = false if item.active and not item.whitelisted
    flag

  getNameAndRealName: (formatting="")->
    obj = @attributes
    name = obj.name
    realName = obj.realName
    return "(Unknown #{obj._id})" if !name and !realName
    if (name and realName) and name != realName
      return "#{name} (#{formatting}#{realName}#{formatting})"
    return realName if realName
    name

  isOfTypes: (types) ->
    userTypes = @get("type")
    return no unless userTypes and types
    types = [types] if typeof types is "string"
    _.any types, (type) -> type in userTypes

  isSubscriber: ->
    @isOfTypes(["subscriber"])

  hasGoldService: ->
    @get('goldService')

  hasFreeGold: ->
    @hasGoldService() and !@get('currentGoldSubscription')

  giveGold: (done)->
    return done(Error('This user already has free gold.')) if @hasGoldService()
    obj =
      goldService: yes
    @simpleSave obj, done

  revokeGold: (done)->
    return done(Error('This user doesn\'t have free gold to revoke.')) if !@hasFreeGold()
    obj =
      goldService: no
    @simpleSave obj, done

  requiresSubscription: (subscription)->
    return false unless @isSubscriber()
    if subscription then !subscription.get('subscriptionActive') else !@get('subscriptionActive')

  # NOTE Questionable logic use subscriber user type instead.
  freeSubscription: ->
    !@get("subscriber") and @isOfTypes(["admin", "licensee"])

  @getMissingFields: (obj, fields)->
    arr = []
    for key in fields
      arr.push(key) unless obj[key]
    return undefined unless arr.length
    arr

  getMissingFields: ->
    fields = requiredFields.all
    if @isOfTypes('artist')
      fields = fields.concat(requiredFields.artist) 
      if @get('paymentType') == 'PayPal'
        fields = fields.concat(requiredFields.payPal)
    UserModel.getMissingFields(@attributes, fields)

  setSignatureImage: (data, done)->
    request
    .put(@signatureUrl())
    .withCredentials()
    .send
      data: data
    .end (err, res)->
      done?(parse.superagent(err, res))

  getSignatureImage: (done)->
    done ?= ->

    request
    .get(@signatureUrl())
    .withCredentials()
    .end (err, res)->
      return done(err) if err = parse.superagent(err, res)
      return done(null, null) unless url = res.body.url

      downloadBinaryToBase64(url, done)

  getReferralUrl: (done)->
    request
    .get("#{@url()}/referral-code")
    .end (err, res)=>
      return done(err) if err = parse.superagent(err, res)
      if res.body and res.body.code
        url = "#{location.protocol}//#{location.host}/#referral/#{res.body.code}"
      else
        url = "No Referral URL"
      return done(null, url)

  canAccessTrack: (track)->
    if @isOfTypes('sync') and not track.onCatalog('sync')
      return false
    true

  syncYouTube: (done)->
    done ?= ->
    request
    .post("#{@url()}/youtube-sync")
    .withCredentials()
    .end (err, res)=>
      done(parse.superagent(err, res), res.body)

  resendInvite: (done)->
    done ?= ->
    request
    .get("#{@url()}/reinvite?returnUrl=" + encodeURIComponent("#{location.protocol}//#{location.host}/#verify/:code"))
    .withCredentials()
    .end (err, res)=>
      done(parse.superagent(err, res), res)

  setTwoFactor: (number, code, done)->
    request.put("#{@url()}/two-factor")
    .send
      number: number
      countryCode: code
    .end (err, res)=>
      done(parse.superagent(err, res))

  disableTwoFactor: (done)->
    request.put("#{@url()}/two-factor/disable")
    .end (err, res)=>
      done(parse.superagent(err, res))

  removeClaims: (vid, done)->
    request.post("#{@url()}/remove-claims-connect")
    .withCredentials()
    .send
      userId: @id
      videoId: vid
    .end (err, res)=>
      done(parse.superagent(err, res), res.body)

module.exports = UserModel
