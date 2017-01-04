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

getYears = (years)->
  return undefined unless years?
  y = (new Date()).getFullYear()
  arr = []
  while y >= 2010
    arr.push
      year: y
      checked: years.indexOf(y) > -1
      text: String(y)
    y--
  # featured
  arr.push
    year: 0
    checked: years.indexOf(0) > -1
    text: "Featured"
  arr

onMarkYear = (e)->
  el = e.currentTarget
  year = parseInt(el.value)
  enabled = el.checked
  years = @model.get('years') or []
  if enabled
    years.push(year)
  else
    index = years.indexOf(year)
    while index != -1
      years.splice(index, 1)
      index = years.indexOf(year)
  @model.simpleSave years: years, (err, model, res, opts)=>
    @toast(err.message, 'error') if err

UserWebsiteDetailsView = v = bQuery.view()

v.ons
  "click [role='markYear']": onMarkYear

v.use View
  className: "user-website-details-view"
  template: require("./template")
  binder: 'property'

v.init (opts={})->
  { @user } = opts
  throw Error('User / Account must be provided') unless @user
  throw Error('A model is required.') unless @model

  if @user.get('websiteDetailsId')
    @model.set('_id', @user.get('websiteDetailsId'))

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
    @renderer.locals.years = getYears(@model.get('years'))
    @renderer.locals.mode = 'view'
    @renderer.render()
    @imageView.render()
    @urlsView.render()
    @n.getEl(".urls").appendChild(@urlsView.el)
    @n.getEl(".picture").appendChild(@imageView.el)

module.exports = v.make()
