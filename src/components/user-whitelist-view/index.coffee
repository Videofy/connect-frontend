request           = require("superagent")
subPlan           = require("subscription-plan")
userWhitelist     = require("user-whitelist")
view              = require("view-plugin")
errorParser       = require('parse')
WhitelistItemView = require("user-whitelist-item-view")

v = bQuery.view()

sel =
  add: "[role='add-channel']"
  save: '[role="save"]'
  container: 'tbody'

v.use view
  className: "user-whitelist-view"
  template: require("./template")

v.init (opts={})->
  @user = opts.user
  @subscription = opts.subscription

  @user.on "change", =>
    @updateView()

v.set 'addNewView', (el, model)->
  @newView.showContextMenu() if @newView
  @newView = null

v.set "render", ->
  @renderer.render()
  @updateView()

v.collection
  append: yes
  tag: sel.container
  createView: (m)->
    newItem = new WhitelistItemView
      model: m
      collection: @collection
      user: @user
      subscription: @subscription
      i18: @i18

    newItem.on 'updateWhitelist', (test)=> @updateWhitelist()
    newItem.on 'removeChannel', (model, view)=> @removeChannel(model, view)
    newItem.on 'updateChannel', (err)=> @displayError(err)

    @newView = newItem if @newChannel
    @newChannel =false

    return newItem

v.set 'displayLoading', (value)->
  @n.evaluateClass("[role='refresh']", "hide", !value)

v.set 'displayError', ( err ) ->
  @n.evaluateClass("[role='error']", "hide", !err)
  @n.setText("[role='error']", err) if err

v.set 'whitelisted', (err)->
  whitelisted = true
  _.each @collection.models, (item)->
    whitelisted = false if item.get('active') and !item.get('whitelisted')
  whitelisted

v.set 'updateView', ->
  return if not el = @n.getEl("[role='status']")
  status = @whitelisted()

  requires = @user.requiresSubscription(@subscription)
  canceling = @subscription?.get('subscriptionCanceling')

  @n.evaluateClass(el, "hide", (@user.get("whitelist") or []).length is 0)
  @n.evaluateClass(el, "fa-check-circle", status)
  @n.evaluateClass(el, "fa-warning", !status and !requires)
  @n.evaluateClass(el, "fa-exclamation-circle", requires)

  if @user.get('subscriber')
    @el.querySelector(sel.add).disabled = if requires or canceling then true else false
    @el.querySelector(sel.save).disabled = if requires or canceling then true else false
    addChannelText = "Add Channel for $4.99/MONTH"
    @n.setText(sel.add, addChannelText)
  else
    @n.evaluateClass(sel.add, "hide", requires)

  title = "Whitelisting is active."
  if !status and !requires
    title = "Your identities are being processed for whitelisting."
  else if requires
    title = "You need to renew your subscription for whitelisting to take effect."
  el.setAttribute("title", title)

v.set 'updateWhitelist', (done)->
  whitelist = []

  _.each @collection.models, (model)->
    channel = model.get('identity')

    if channel
      item =
        name: model.get 'name'
        identity: channel
        active: model.get('active')
        whitelisted: model.get('whitelisted')

      whitelist.push item

  @displayLoading(true)
  @displayError(null)

  params =
    whitelist: whitelist
    user: @user

  userWhitelist.updateWhitelist params, (err, res)=>
    @displayLoading(false)
    err = errorParser.superagent(err, res)
    return @displayError(err) if err
    if res.status isnt 200
      err = res.body?.error or "An error occured."
      return @displayError(err)
    @user.fetch({ success: ()=>
      return done() if done
    })

v.set 'updateWhitelistView', ->
  whitelist = @el.querySelector(sel.container)
  whitelist.innerHTML = ""
  @collection.reset()
  @collection.fetch()

v.on "click #{sel.save}", ->
  @updateWhitelist => @updateWhitelistView()

v.set 'updatePlan', (channelNum, period, userTypes)->
  subPlan.getPlan { channelNum: channelNum, period: period, userTypes: userTypes }, (err, plan)=>
    subPlan.setPlan { plan: plan, subId: @subscription.id }, (err, res)=>
      unless res.status is 200
        return alert(res.body or "error on add channel")
      if res.body.approvalUrl
        window.location.replace(res.body.approvalUrl)
      else
        @user.fetch({ success: ()=>
          @updateWhitelistView()
        })

v.on "click #{sel.add}", ->
  next = =>
    request
    .post("/subscription/addChannel/#{@subscription.id}")
    .withCredentials()
    .end ( err, res ) =>
      err = errorParser.superagent(err, res)
      return alert(err) if err
      unless res.status is 200
        return alert(res.body?.error or "error on add channel")
      if res.body.approvalUrl
        window.location.replace(res.body.approvalUrl)
      else
        @user.fetch
          success: =>
            @updateWhitelistView()

  unless @user.get('subscriber')
    return next()

  if confirm("Confirm adding channel for 4.99$/MONTH") # TODO remove hardcode
    next()

v.set 'hasTwitch', ->
  twitchChannels = _.filter @collection.models, (model)->
    model.attributes.name is 'twitch'

  if twitchChannels.length <= 1
    return false
  else
    return true

v.set 'removeChannel', (model, view)->
  return alert("Can't remove more channels") if @collection.models.length <= 2

  if @user.get 'subscriber'
    if !@hasTwitch() and model.get('name') is 'twitch'
      return alert("Can't remove the Twitch channel slot")

    @updateWhitelist ()=>
      planId = @subscription.get("subscriptionPlan")
      subPlan.getPlan { planId: planId }, (err, oldPlan)=>
        @updatePlan(oldPlan.channelNum - 1, oldPlan.period, oldPlan.userTypes)
  else
    model.destroy()
    view.remove()
    channelNumber = @user.get('channelNumber') or 2
    chanelNumber = Math.max(2, channelNumber-1)
    @user.set 'channelNumber', channelNumber
    @user.save()

module.exports = v.make()

