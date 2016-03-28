countries = require('countries')
view = require('view-plugin')

v = bQuery.view()

v.use view
  className: 'user-shop-info-view'
  template: require('./template')
  binder: 'property'
  locals:
    countries: countries.map((country)-> country.name)

v.init (opts={})->
  { @user } = opts
  throw Error('A model is required.') unless @model
  throw Error('A user is required.') unless @user

  unless @user.get('shopInfoId')
    @model.once 'sync', (model)=>
      @user.update
        shopInfoId: @model.id

v.set 'render', ->
  @model.toPromise().then =>
    @renderer.render()

module.exports = v.make()
