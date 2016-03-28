view = require('view-plugin')
countries = require('countries')

onKeyUp = (e)->
  return unless e.keyCode is 13
  onClickClose.call(@, e)

onClickClose = (e)->
  return @trigger('close') unless missing = @model.getMissingFields()
  window.alert('Please complete all the fields.')

UserCompleteDetailsView = v = bQuery.view()

v.use view
  className: 'user-complete-details-view'
  template: require('./template')
  binder: 'property'
  locals: ->
    permissions: @permissions
    countries: countries.map((country)-> country.name)

v.on 'click [role="complete"]', onClickClose
v.on 'keyup input', onKeyUp

v.init (opts={})->
  throw Error('User model required.') unless @model

v.set 'render', ->
  @renderer.render()

module.exports = v.make()
