eurl    = require('end-point').url
request = require("superagent")

ex = subscriptionPlan = module.exports

subscriptionPlan.getPlan = (params, done)->
  request
  .get(eurl("/subscription/plan-by-config"))
  .withCredentials()
  .query params
  .send()
  .end ( err, res ) =>
    return alert(err) if err
    if res.status isnt 200
      return alert(res.body.error or "Can't find plans from the config.")
    else
      return done(null, res.body)

subscriptionPlan.setPlan = (params, done)->
  { plan, subId } = params
  request
  .post(eurl("/subscription/update/#{subId}"))
  .withCredentials()
  .send
    plan: plan
  .end ( err, res ) =>
    return done(err, res)

subscriptionPlan.getPlansByUserTypes = (params, done)->
  { userTypes, active } = params
  request
  .get(eurl("/subscription/plans-by-user-types"))
  .withCredentials()
  .query
    userTypes: userTypes
    active: active
  .send()
  .end ( err, res ) =>
    return alert(err) if err
    if res.status isnt 200
      return alert(res.body.error or "Can't find plans from user types.")
    else
      return done(null, res.body)
