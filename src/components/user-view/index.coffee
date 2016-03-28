
User = require('user-model')
mkUserBodyView = require('user-body-view')

mkUserView = (config={}) ->
  v = bQuery.view()
  { permissions } = config
  perms = permissions.user
  isVisibility = yes

  UserBodyView = mkUserBodyView config

  v.defaults 'user',
    rawModel: yes
    templateData:
      permissions: perms
      rootpermissions: permissions
  v.scrollIntoView()

  v.pane
    el: -> @bodyEl

  if perms.delete
    v.tip
      tag: ".user-delete-inner"
      message: "Delete User"
      position: "north"
    v.delete(".user-delete", name: -> @model.nameWithEmail())
    v.mouseOvers("", ".user-delete", isVisibility)

  bound = [
      "realName"
    , "name"
  ]

  for b in bound
    v.boundText b, ".user-#{b}", _.identity

  v.boundText "type", ".user-type", (t) -> t.join(", ")

  v.init (opts={})->
    d = {}
    _(d).extend opts
    d.el = opts.bodyEl
    @fragment = opts.frag
    @bodyEl = opts.bodyEl?.parentNode

    @bodyView = new UserBodyView d

    @once "pane:open", => @bodyView.render()
    @on "pane:open", =>
      setTimeout @scrollIntoView.bind(@), 150

  v.make()

module.exports = mkUserView
