SuperModel = require("super-model")

class SubscriptionModel extends SuperModel

  urlRoot: "/subscription"

  getPaymentDate: (user)->
    periodEndFormated = @getAsFormatedDate("subscriptionPeriodEnd")
    status = @getSubscriptionStatus(user)
    if status is 'active'
      return "Next payment on #{periodEndFormated} "
    else
      return "Subscription ends on #{periodEndFormated} "

  getSubscriptionStatus: (user)->
    active = !user.requiresSubscription(@)
    canceling = @get('subscriptionCanceling') or false

    if !active or !user.get("subscriber")
      return 'inactive'
    else if canceling
      return 'canceling'
    else
      return 'active'

  displayPlanName: (user, plan)->
    type = if user.isOfTypes("golden") then "Gold" else "Licensee"
    channel = if user.isOfTypes("golden") then "" else "#{plan.channelNum} channels"

    if plan.period > 1
      duration = "#{plan.period} Months"
    else
      duration = "#{plan.period} Month"

    return "Monstercat #{type} Subscription #{channel} #{duration} "

  getPlanName: (user, plans)->
    status = @getSubscriptionStatus(user)
    if status is 'inactive'
      planName = "Subscription Inactive"
    else
      planName = @displayPlanName(user, @getPlan(plans))

    return planName

  getPlan: (plans)->
    plans = plans or []
    planId = @get("subscriptionPlan")
    return @getBasePlan(plans) unless @get("subscriptionActive")

    if @get("subscriptionPlanDetails") and @get("subscriptionPlanDetails").planId
      result = @get("subscriptionPlanDetails")
    else if planId
      result = _.find plans, (plan)-> plan.planId is planId
    else
      result = @getBasePlan(plans)

    return result

  getBasePlan: (plans)->
    result = _.find plans, (plan)->
      return "#{plan.channelNum}" is '2' and "#{plan.period}" is '1'

    return result

module.exports = SubscriptionModel
