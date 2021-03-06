request           = require("superagent")
subPlan           = require("subscription-plan")
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

v.set 'addNewView', (el, model)->
  @newView.showContextMenu() if @newView
  @newView = null

v.set "render", ->
  @renderer.locals.whitelistLicense = @permissions.canAccess('self.whitelistLicense')
  @renderer.locals.user = @user
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

    newItem.on 'removeChannel', (err)=>
      return @displayError(err) if err
      @removeChannel()

    newItem.on 'updateChannel', (err, model, view)=>
      return @displayError(err) if err
      @user.fetch
        success: (model, res, opt)=>
          @updateWhitelistView ()=> @updateView()

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
  whitelisted = @whitelisted()

  requires = @user.requiresSubscription(@subscription)
  canceling = @subscription?.get('subscriptionCanceling')
  activeChannels = _.find @collection.models, (i)-> i.get('active')

  @n.evaluateClass(el, "hide", !activeChannels)
  @n.evaluateClass(el, "fa-check-circle", whitelisted)
  @n.evaluateClass(el, "fa-warning", !whitelisted and !requires)
  @n.evaluateClass(el, "fa-exclamation-circle", requires)

  if @user.get('subscriber')
    @el.querySelector(sel.add).disabled = if requires or canceling then true else false
    addChannelText = "Add Channel for $4.99/MONTH"
    @n.setText(sel.add, addChannelText)
  else
    @n.evaluateClass(sel.add, "hide", requires)

  title = "Whitelisting is active."
  if !status and !requires
    title = "Your identities have been whitelisted."
  else if requires
    title = "You need to renew your subscription for whitelisting to take effect."
  el.setAttribute("title", title)

v.set 'updateWhitelistView', (cb)->
  whitelist = @el.querySelector(sel.container)
  whitelist.innerHTML = ""
  @collection.reset()
  @collection.fetch
    success: => cb?()

v.set 'updatePlan', (channelNum, period, userTypes)->
  subPlan.getPlan { channelNum: channelNum, period: period, userTypes: userTypes }, (err, plan)=>
    subPlan.setPlan { plan: plan, subId: @subscription.id }, (err, res)=>
      unless res.status is 200
        return alert(res.body or "error on add channel")
      if res.body.approvalUrl
        window.location.replace(res.body.approvalUrl)
      else
        @user.fetch
          success: ()=>
            @updateWhitelistView ()=> @updateView()

v.on "click #{sel.add}", ->
  next = =>
    request
    .post("/subscription/addChannel/#{@subscription.id}")
    .withCredentials()
    .send
      approvedRedirectUrl: "#{window.location.origin}/#profile"
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
            @updateWhitelistView ()=> @updateView()

  unless @user.get('subscriber')
    return next()

  if confirm("Confirm adding channel for 4.99$/MONTH") # TODO remove hardcode
    next()

v.set 'removeChannel', ->
  planId = @subscription.get("subscriptionPlan")
  subPlan.getPlan { planId: planId }, (err, oldPlan)=>
    @updatePlan(oldPlan.channelNum - 1, oldPlan.period, oldPlan.userTypes)

module.exports = v.make()

