view    = require("view-plugin")
subPlan = require("subscription-plan")
request = require("superagent")

UpdateSubscriptionView = v = bQuery.view()

v.use view
  className: "update-subscription-view"
  template: require("./template")

v.on "change .type-select-update", 'subTypeChange'
v.on "click [role='update-subscription']", "updateSubscription"
v.on "click [role='cancel-subscription-update']", "cancelSubscription"

v.set 'cancelSubscription', ->
  @trigger 'cancelSubscription'

v.set "render", ->
  @renderer.render()
  @getUserPlan =>
    @stopListening(@model)
    @listenTo @model, 'change:subscriptionPlan', =>
      @getUserPlan => @updateView()
    @updateView()

v.set 'subTypeChange', (e)->
  gold = if e.target.value is 'gold' then true else false
  if gold
    userTypes = ["subscriber", "golden"]
  else
    userTypes = ["subscriber", "licensee"]

  next = =>
    subPlan.getPlan
      channelNum: @plan.channelNum
      period: @plan.period
      userTypes: userTypes
    , (err, plan)=>
      @plan = plan
      @updateView()

  return @getUserPlan(next) if !@plan?
  next()

v.set 'getUserPlan', (done)->
  planId = @model.get("subscriptionPlan")
  unless planId
    @plan = { channelNum: 2, period: 1, description: "$9.99/MONTH" }
    return done(@plan)

  subPlan.getPlan { planId: planId }, (err, plan)=>
    @plan = plan
    @userPlan = plan
    return done(@plan)

v.set 'updateView', ->
  @n.evaluateClass(".update-sub-type", "hide",
    @userPlan and !@userPlan.goldPlan)
  @n.setText("label.ss.subscription-cost", @plan.description)
  updateBtn = @el.querySelector("[role='update-subscription']")
  month = if @plan.period <=1 then "Month" else "Months"
  @el.querySelector(".interval").innerHTML = "#{@plan.period} #{month}"

  splan = @model.get("subscriptionPlan")
  if splan and splan is @plan.planId
    updateBtn.setAttribute("disabled", true)
  else if @userPlan and (@userPlan.period > @plan.period)
    updateBtn.setAttribute("disabled", true)
  else
    updateBtn.removeAttribute("disabled")

v.set 'updateSubscription', ->
  return unless confirm("You are about to update your subscription. Are you sure you want to do this?")
  subPlan.setPlan { plan: @plan, subId: @model.id }, (err, res)=>
    return alert(err) if err
    if res.status isnt 200
      return alert(res.body?.error or "Unable to update subscription")
    if res.body.approvalUrl
      window.location.replace(res.body.approvalUrl)
    else
      @model.fetch()

module.exports = v.make()
