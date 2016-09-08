eurl          = require('end-point').url
parse         = require('parse')
request       = require('superagent')
SuperModel    = require("super-model")
WhitelistItem = require('whitelist-item-model')
{ downloadBinaryToBase64 } = require('binary-downloader')

WhitelistCollection = Backbone.Collection.extend { model: WhitelistItem }

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

getWhitelist = (whitelist, name)->
  _.filter whitelist, (item)-> item.name is name

class UserModel extends SuperModel

  urlRoot: '/api/user'

  signatureUrl: ->
    eurl("#{@url()}/signature")

  impersonateUrl: ->
    url = @url() + '/impersonate'

  initialize: (params, opts)->
    return unless params
    @setUpChannels(params)
    @youtubeCollection = new WhitelistCollection @ytChannels
    @twitchCollection = new WhitelistCollection @twitchChannels

  updateWhitelist: ->
    params = { whitelist: @get 'whitelist' }
    @setUpChannels(params)
    @youtubeCollection.reset @ytChannels
    @twitchCollection.reset @twitchChannels
    @trigger 'updatedWhitelist'

  setUpChannels: (params)->
    @whitelist = @getWhitelist(params)
    @ytChannels = getWhitelist(@whitelist, 'youtube')
    @twitchChannels = getWhitelist(@whitelist, 'twitch')

  getWhitelist: (params)->
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
    .post("#{@url()}/reinvite")
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
