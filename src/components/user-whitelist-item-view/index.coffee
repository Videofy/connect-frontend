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
  @renderer.render()
  @updateView()

v.set "updateView", ->
  active = !@user.requiresSubscription(@subscription)
  canceling = @subscription?.get('subscriptionCanceling')
  @n.setText(sel.channelType,
    @i18.strings.channelTypes[@model.get 'name'])
  @n.setText(sel.channelName, @model.get 'identity')

  if @user.isSubscriber()
    hideRemove = !active or canceling
    @n.evaluateClass(sel.btn.remove, "hide", hideRemove)
  else
    @n.evaluateClass(sel.btn.remove, "hide", @model.get('identity'))

  state = userWhitelist.getState(@model.get('active'), @model.get('whitelisted'))
  iconClass = userWhitelist.getIcons()[state]
  stateIcon = @el.querySelector(sel.status)
  stateIcon.className = iconClass
  stateIcon.setAttribute("title", userWhitelist.state[state].tipPublic)

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
  @trigger 'updateChannel', err

v.set 'onChangeChannel', (e)->
  el = @n.getEl(sel.channelName)
  id = e.currentTarget.value
  @model.set('identity', id)
  userWhitelist.validate @model.get('name'), id, (err)=>
    @displayError(err, el)

v.on 'mouseover .channel-status', ->
  @trigger 'showLegend'

v.on 'mouseleave .channel-status', ->
  @trigger 'hideLegend'

v.set 'openChannelSelect', ->
  select = @el.querySelector(sel.channelType)
  select.onclick()

v.on "click #{sel.btn.remove}", (e)->
 if confirm("Confirm to remove channel and downgrade the subscription plan.")
   if @model.get 'identity'
     @model.set 'active', false
     @trigger 'removeChannel', @model, @
   else
     @trigger 'removeChannel', @model, @

v.set 'hasTwitch', ->
  twitchChannels = _.filter @collection.models, (model)-> model.attributes.name is 'twitch'
  if twitchChannels.length <= 1
    return false
  else
    return true

module.exports = v.make()
