parse          = require('parse')
view           = require("view-plugin")
sortutil       = require('sort-util')
ListManageView = require("list-manage-view")
LabelView      = require("label-view")

UserInviteView = v = bQuery.view()

getSelectVal = (el) ->
  el.options[el.selectedIndex].value

required =
  _any:
    name: true
    email: true
  artist:
    name: true
    realName: true
    email: false

validate = (attrs)->
  if 'artist' in attrs.type
    map = required['artist']
  else
    map = required._any

  errs = Object.keys(map)
    .map (key)->
      if map[key] and !attrs[key]
        return Error("Missing the user's property #{key}.")
      return undefined
    .filter (err)->
      !!err

  return undefined if !errs.length

  errs

v.use view
  className: "user-invite-view"
  template: require("./template")

v.ons
  "click [role='submit']": "submit"

v.init (opts={}) ->
  { @router  } = opts
  @userTypes = []
  stringTypes = @i18.strings.userTypes
  types = @permissions.user.typesManaged
  @typeSelector = new ListManageView
    items: []
    createView: (item)->
      lview = new LabelView
      lview.el.textContent = stringTypes[item]
      lview
    createItem: (value, text)->
      value
    getOptions: ->
      Object.keys(types)
      .map (type)->
        text: stringTypes[type] or type
        value: type
      .sort (a, b)->
        sortutil.strings(a.text, b.text)
  @typeSelector.on 'viewadd', @changeTypes.bind(@)
  @typeSelector.on 'viewremove', @changeTypes.bind(@)

v.set 'changeTypes', (view, item, items)->
  @n.evaluateClass("[role='trial-period']", 'hide', 'subscriber' not in items)
  @n.evaluateClass("[role='username-field']", 'hide', 'artist' not in items)
  @userTypes = items

v.set "render", ->
  @renderer.render()
  @typeSelector.render()
  @n.getEl(".types").appendChild(@typeSelector.el)

v.set 'getTrialEndDate', ->
  months = @el.querySelector("[property='trialLength']").value
  return null if months <=0
  now = new Date()
  return now.setDate(now.getDate() + months*31)

v.set "submit", ->
  attrs = {}
  els = Array.prototype.slice.call(@el.querySelectorAll('[property]'))
  els.forEach (el)->
    attrs[el.getAttribute('property')] = String(el.value).trim()

  attrs.type = @userTypes
  attrs.name = attrs.realName unless 'artist' in attrs.type

  return alert('Please fill out all fields.') if validate(attrs)

  if @n.getEl('[role="send-invite"]')?.checked
    type = if 'subscriber' in @userTypes then 'sign-up' else 'verify'
    attrs.returnUrl = "#{location.protocol}//#{location.host}/##{type}/:code"

  if @el.querySelector("[property='trialLength']")?.value
    attrs.trialAccessEndDate = @getTrialEndDate()

  btn = @n.getEl('[role="submit"]')
  btn.classList.add('active')
  btn.disabled = true
  resetBtn = ->
    btn.classList.remove('active')
    btn.disabled = false

  @collection.create attrs,
    wait: true
    success: (model, res)=>
      @toast "User successfully created.", 'success'
      @router.navigate("/#community", trigger: true)
      resetBtn()
    error: (model, res)=>
      @toast parse.backbone.error(res).message, 'error'
      resetBtn()

module.exports = v.make()
