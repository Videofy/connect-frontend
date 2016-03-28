view = require('view-plugin')
countries = require('countries')
parse = require('parse')

cc = {}
countries.forEach (country)->
  cc[country.alpha3] = country.name

onClickDelete = (e)->
  return unless window.confirm("Are you sure you want to delete this effect?")
  @model.destroy
    wait: true
    error: (model, res, opts)=>
      @toast(parse.backbone.error(res).message, 'error')
    success: (model, res, opts)=>
      @toast("The effect was succesfully deleted.", 'error')

v = bQuery.view()

v.use view
  tagName: 'tr'
  template: require('./rate-row-template')
  binder: 'property'
  locals: ->
    countries: cc
    effects:
      'single': 'Single'
      'release10': 'Over 10 Tracks'

v.ons
  'click [role="destroy-effect"]': onClickDelete

v.init (opts={})->
  throw Error('Model not provided.') unless @model

v.set 'render', ->
  @renderer.render()

module.exports = v.make()
