InputBinder = require("input-binder")
InputListView = require("input-list-view")
UserProfileImageView = require("user-profile-image-view")
View = require("view-plugin")

syncName = ->
  @model.save
    name: @user.get('name')
  ,
    patch: true
    wait: true

UserWebsiteDetailsView = v = bQuery.view()

v.use View
  className: "user-website-details-view"
  template: require("./template")
  binder: 'property'

v.init (opts={})->
  { @user } = opts
  throw Error('User / Account must be provided') unless @user

  @model.once 'sync', (model)=>
    return if @user.get('websiteDetailsId')
    syncName.call(@)
    @user.update
      websiteDetailsId: model.id
    ,
      wait: true
      patch: true

  @urlsView = new InputListView
    model: @model
    property: "urls"
    placeholder: "URL"

  @imageView = new UserProfileImageView(opts)

v.set "render", ->
  @renderer.locals.mode = 'loading'
  @renderer.render()
  @model.toPromise(yes).then =>
    @renderer.locals.mode = 'view'
    @renderer.render()
    @imageView.render()
    @urlsView.render()
    @n.getEl(".urls").appendChild(@urlsView.el)
    @n.getEl(".picture").appendChild(@imageView.el)

module.exports = v.make()
