InputListView  = require("input-list-view")
LabelView      = require("label-view")
ListManageView = require("list-manage-view")
view           = require("view-plugin")

UserAdminView = v = bQuery.view()

onClickResendInvite = (e)->
  @model.resendInvite (err)=>
    return @toast(err, 'error') if err
    @toast("Invite resent.")

onClickYouTubeSync = (e)->
  @model.syncYouTube (err, res)=>
    return @toast(err, 'error') if err
    @toast('YouTube channel synced')

v.use view
  className: "user-admin-view"
  template: require("./template")

v.init (opts={})->
  # Duplicate code
  fn = (property)=> (view, item, items)=>
    @model.save property, items,
      patch: true
      wait: true
      error: (model, res, opts)=>
        @toast(JSON.parse(res.responseText).message, 'error')

  @namesView = new InputListView
    model: @model
    property: "altNames"
    placeholder: "Alternative Name"
    disabled: !@permissions.admin

  @claimsView = new InputListView
    model: @model
    property: "claimIds"
    placeholder: "Identifier"
    disabled: !@permissions.admin

  types = {}
  Object.keys(@permissions.user.typesManaged).forEach (type)=>
    types[type] = @i18.strings.userTypes[type]

  @typeSelector = new ListManageView
    items: @model.get("type")
    createView: (item)->
      lview = new LabelView
      lview.el.textContent = types[item]
      lview
    createItem: (value, text)->
      value
    getOptions: ->
      Object.keys(types).map (key)=>
        value: key
        text: types[key]
  @typeSelector.on 'viewadd', fn("type")
  @typeSelector.on 'viewremove', fn("type")

  @listenTo @model, "change:type", @onUserTypeChange.bind(@)

v.ons
  'click [role="resend-invite"]': onClickResendInvite
  'click [role="youtube-sync"]': onClickYouTubeSync

v.set "render", ->
  @renderer.render()
  @namesView.render()
  @claimsView.render()
  @typeSelector.render()

  @n.getEl(".names").appendChild(@namesView.el)
  @n.getEl(".claims > .ids").appendChild(@claimsView.el)
  @n.getEl(".types").appendChild(@typeSelector.el)

  @onUserTypeChange()

v.set "onUserTypeChange", ->
  return if !@el.firstChild
  @n.evaluateClass(".alternative-names", "hide", !@model.isOfTypes("artist"))

module.exports = v.make()
