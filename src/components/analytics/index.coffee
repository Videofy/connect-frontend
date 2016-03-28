debug    = require("debug")("connect:analytics")
eurl     = require('end-point').url
humanize = require('humanize-string')
request  = require("superagent")

#
# Handle analytics events
#
exports = module.exports = (opts) ->
  { analytics, events, user, player } = opts

  if user.get("email")
    debug('identify', user)
    analytics.identify user.id,
      username: user.get('name')
      name: user.get('realName')
      email: user.get('email')
      id: user.id
      type: user.get('type')

  exports.registerApplicationEvents(events, analytics)
  exports.registerPlayerEvents(player, analytics)
  exports.registerDownloadEvents(events, analytics)

exports.playerEvents = [
  'play'
  'stop'
  'pause'
  'next'
  'previous'
  'ended'
  'error'
  'add'
]

#
# Basic Application
#
applicationEvents =
  "signout": "Signed Out"
  "signup:verify-success": "Verification Succeeded"
  "signup:verify-failed":
    event: "Verification Failed"
    parse: (error)-> error
  "player:mode-changed": # TODO Move this to the player!
    event: "Player Mode Changed"
    parse: (player, mode)->
      mode: mode
      enabled: player[mode]
  "rightclick":
    event: "Right Clicked"
    parse: (el)->
      return false if not el
      str = el.tagName.toLowerCase()
      if el.id
        str += "##{el.id}"
      if el.classList.length
        str += "." + Array.prototype.join.call(el.classList, ".")
      str
  "subscription:cancled": "Subscription Canceled"
  "subscription:charged-stripe": "Subscription Charged via Stripe"
  "subscription:added-paypal": "Subscription added via Paypal"
  "subscription:added-stripe": "Subscription added via Stripe"

exports.registerApplicationEvents = (events, analytics)->
  cb = (a, v)-> ->
    return a.track(v) if typeof v is "string"
    attrs = v.parse.apply(v, arguments)
    a.track(v.event, attrs) if attrs?

  for k, v of applicationEvents
    events.on k, cb(analytics, v)

#
# Audio Player
#
exports.registerPlayerEvents = (player, analytics) ->
  _.each exports.playerEvents, (e) ->
    player.on e, (item) ->
      { track, release, playedTime } = item

      eventData =
        createdDate: new Date(track.get('created')) # For old support?
        genre: track.get('genre')
        isrc: track.get('irsc')
        release: release.get('title')
        releaseId: release.id
        releaseDate: new Date(release.get('releaseDate'))
        track: track.get('title')
        trackId: track.id
        title: track.get('title')
        displayTitle: track.displayTitle()
        upc: release.get('upc')
        playedTime: playedTime

      analytics.track "Audio Player #{humanize(e)}", eventData
      exports.track "Audio Player #{humanize(e)} Server Side", eventData
      debug("audio player event #{e}", item)

#
# Send and record event on server side
#
exports.track = (event, data) ->
  request
    .post(eurl("/analytics/record/event"))
    .withCredentials()
    .send
      event: event
      properties: data
    .end (err, res) ->
      debug("record server side event #{event}", data)

#
# Generic Track model events
#
exports.trackEvent = (event, model, attrs={}) ->
  attrs.title ?= model.get('title')
  attrs.genre ?= model.get('genre')
  attrs.isrc ?= model.get('isrc')
  attrs.createdDate ?= model.get('created')
  attrs.from = humanize(attrs.from) if attrs.from
  analytics.track event, attrs

#
# Download events
#
exports.registerDownloadEvents = (events, analytics) ->
  events.on 'page', (page) ->
    debug('page', page)
    analytics.page(humanize(page))

  # TODO Move to server.
  events.on "download:statement", (model, attrs={}) ->
    _.extend(attrs, model.attributes)
    analytics.track 'Statement Download', attrs
