menu = require("context-menu-plugin")
Promise = require('bluebird')
userWhitelist = require("user-whitelist")
view = require("view-plugin")

v = bQuery.view()

v.use view
  className: "channel-row"
  template: require("./template")

v.init (opts={})->
  { @user, @subscription } = opts
  throw Error("A user must be provided.") unless @user

v.use menu
  name: "optionMenu"
  ev: "click [role='status']"
  open: (source, menu)->
    state = userWhitelist.getState(@model.get('active'),
      @model.get('whitelisted'))
    select = userWhitelist.getSelect(state)
    arr = Object.keys(select).map (key)->
      name: userWhitelist.state[key].tipPublic
      value: select[key]
    menu.setItems(arr)
  select: (item, menu)->
    state = item.value
    @model.set 'active', state.active
    @model.set 'whitelisted', state.whitelisted
    @model.save()
    @user.fetch()

v.on "click [role='link']", (e)-> e.stopPropagation()

v.set "render", ->
  @renderer.render()
  @updateView()

v.set 'updateView', ->
  @model.set('active', false) if @user.requiresSubscription(@subscription)
  state = userWhitelist.getState(@model.get('active'),
    @model.get('whitelisted'))

  status = @n.getEl('[role="status-icon"]')
  status.className = userWhitelist.getStateIcon(state)
  status.setAttribute("title", userWhitelist.state[state].tipPublic)

v.set "whitelisted", (done)->
  new Promise (res, rej)=>
    @model.set('whitelisted', @model.get('active'))
    @model.save({}, {err: rej, success: res} )
    @updateView()

module.exports = v.make()
