ex = userWhitelist = module.exports
parseChannel = require('parse-youtube-user')
request = require("superagent")

# To do: share the states with backend
userWhitelist.state =
  whitelisting:
    icon: "fa fa-exclamation-circle ss cl-warning"
    tip: "need add to whitelist"
    iconPublic: "fa fa-exclamation-circle cl-warning"
    tipPublic: "Waiting to be whitelisted."
    status:
      active: true
      whitelisted: false
    nextState: "whitelisted"
  whitelisted:
    icon: "fa fa-check-circle"
    tip: "added to whitelist"
    iconPublic: "fa fa-check-circle"
    tipPublic: "Identity has been whitelisted."
    status:
      active: true
      whitelisted: true
  removing:
    icon: "fa fa-minus-circle ss cl-danger"
    tip: "need to remove from whitelist"
    iconPublic: "fa fa-minus-circle"
    tipPublic: "Waiting to be removed from whitelist."
    status:
      active: false
      whitelisted: true
    nextState: "inactive"
  inactive:
    icon: "fa fa-minus-circle"
    tip: "Inactive"
    iconPublic: "fa fa-minus-circle"
    tipPublic: "Subscription inactive, no action required."
    status:
      active: false
      whitelisted: false

userWhitelist.getIcons = ->
  item = {}
  for state, attrs of userWhitelist.state
    item[state] = attrs.icon
  return item

userWhitelist.getLegend = (params)->
  pub = params?.public or false

  items = []
  for state, attrs of userWhitelist.state
    item = {}
    icon = document.createElement('i')
    icon.className = if pub then attrs.iconPublic else attrs.icon
    item.key = icon
    item.value = if pub then attrs.tipPublic else attrs.tip
    items.push item

  return items

userWhitelist.getSelect = (currentState)->
  currentDetail = userWhitelist.state[currentState]
  item = {}
  for state, attrs of userWhitelist.state
    if state is currentState or currentDetail.nextState is state
      item[state] = attrs.status

  return item

userWhitelist.getStateIcon = (state)->
  icon = userWhitelist.getIcons()[state]
  return icon

userWhitelist.getState = (active, whitelisted)->
  whitelisted = whitelisted or false
  active = active or false

  result = 'inactive'
  for state, attrs of userWhitelist.state
    if active is attrs.status.active and whitelisted is attrs.status.whitelisted
      result = state

  return result

userWhitelist.updateWhitelist = (params, done)->
  { whitelist, user } = params
  request
  .post("/user/update/whitelist/#{user.id}")
  .send(whitelist)
  .end ( err, res ) =>
    return done(err, res)

userWhitelist.validate = (type, id, done)->
  return done(null) unless id

  id = parseChannel(id) if type is 'youtube'

  request
  .get("/validate/vendor/#{type}/#{id}")
  .end (err, res)=>
    return done(err.message) if err
    if res.status isnt 200
      err = res.body?.error or "An error occured."
      return done(err)
    if !res.body.isValid
      return done("'#{id}' is not a valid #{type} identity.")

    done(null, id)

module.exports = userWhitelist
