userWhitelist = require("user-whitelist")
ContextMenu = require("context-menu-plugin")
View = require("view-plugin")
Enabler = require("enabler")

v = bQuery.view()

options =
  name:
    "youtube": 1
    "twitch": 2

sel =
  channelType: "[role='channel-type']"
  channelName: "[role='channel-name']"
  btn:
    remove: '[role="remove-channel"]'
  status: '[role="status-icon"]'
  loading: '[role="loading"]'

v.use View
  tagName: 'tr'
  template: require("./template")

v.ons
  "change [role='channel-name']": "onChangeChannel"

v.init (opts={})->
  { @newChannel, @user, @subscription } = opts
  @listenTo @user, "change", @updateView.bind(@)

v.set 'showContextMenu', ->
  select = @el.querySelector(sel.channelType)
  position = select.getBoundingClientRect()
  @optionMenu.open(position.left + 10, position.top + 10, select)

v.set "render", ->
  @renderer.locals.user = @user
  @renderer.render()
  @updateView()

v.set "updateView", ->
  active = !@user.requiresSubscription(@subscription)
  canceling = @subscription?.get('subscriptionCanceling')
  unless @loading
    @n.setText(sel.channelType,
      @i18.strings.channelTypes[@model.get 'name'])
    @n.setText(sel.channelName, @model.get 'identity')

  if @user.isSubscriber()
    hideRemove = !active or canceling
    @n.evaluateClass(sel.btn.remove, "hide", hideRemove)
  else
    @n.evaluateClass(sel.btn.remove, "hide", @model.get('identity'))

  state = userWhitelist.getState(@model.get('active'), @model.get('whitelisted'))
  stateIcon = @el.querySelector(sel.status)
  stateIcon.className = userWhitelist.getIcons()[state]
  stateIcon.setAttribute("title", userWhitelist.state[state].tipPublic)

  @n.evaluateClass(sel.status, "hide", @loading)
  @n.evaluateClass(sel.loading, "hide", !@loading)

v.use ContextMenu
  name: "optionMenu"
  ev: "click [option]"

v.set "onOpenContextMenu", (source, menu)->
  return if @model.get('identity') or @model.get('fixed')
  op = source.getAttribute("option")
  ops = options[op]

  arr = Object.keys(ops).map (key)->
    name: key
    value: key
    option: op
  menu.setItems(arr)

v.set "onSelectContextMenu", (item, menu)->
  if !@hasTwitch() and @model.get('name') is 'twitch'
    return alert("You can't change the last Twitch channel.")

  @n.setText("[option='#{item.option}'", item.name)
  @model.set 'name', item.name

v.set 'displayError', (err, el)->
  @n.evaluateClass(el, "ok", !err)
  @n.evaluateClass(el, "error", err?)

v.set 'onChangeChannel', (e)->
  el = @n.getEl(sel.channelName)
  newChannel = e.currentTarget.value
  userWhitelist.validate @model.get('name'), newChannel, (err)=>
    return @displayError(err, el) if err
    @loading = true
    @updateView()
    @model.updateChannel @user.id, newChannel, @model.get('name'), (err, res)=>
      @loading = false
      return @displayError(err, el) if err
      @trigger 'updateChannel', err

v.on 'mouseover .channel-status', ->
  @trigger 'showLegend'

v.on 'mouseleave .channel-status', ->
  @trigger 'hideLegend'

v.set 'openChannelSelect', ->
  select = @el.querySelector(sel.channelType)
  select.onclick()

v.on "click #{sel.btn.remove}", (e)->
  return alert("Can't remove more channels") if @collection.models.length <= 2

  if !@hasTwitch() and @model.get('name') is 'twitch'
    return alert("Can't remove the Twitch channel slot")

  if confirm("Confirm to remove channel and downgrade the subscription plan.")
    @loading = true
    @updateView()
    @model.removeChannel @user.id, @model.get('name'), (err, res)=>
      @loading = false
      return @displayError(err, @el) if err
      @trigger 'removeChannel', err

v.set 'hasTwitch', ->
  twitchChannels = _.filter @collection.models, (model)-> model.attributes.name is 'twitch'
  if twitchChannels.length <= 1
    return false
  else
    return true

module.exports = v.make()
