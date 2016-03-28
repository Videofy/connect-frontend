view = require('view-plugin')

v = bQuery.view()

v.use view
  className: 'search-results-view ss'
  template: require('./template')

v.init (opts={})->
  { @empty, @prompt } = opts
  @renderer.locals.items = []
  @renderer.locals.empty = @empty or 'No results.'
  @renderer.locals.prompt = @prompt or 'Search for items.'
  @hide()

v.set 'setResults', (arr)->
  @renderer.locals.showPrompt = false
  @renderer.locals.items = arr
  @render()

v.set 'render', ->
  @renderer.locals.mode = 'view'
  @renderer.render()

v.set 'showLoading', ->
  @renderer.locals.showPrompt = true
  @renderer.locals.mode = 'loading'
  @renderer.render()
  @show()

v.set 'showPrompt', ->
  @renderer.locals.showPrompt = true
  @renderer.locals.mode = 'view'
  @renderer.render()
  @show()

v.set 'hide', ->
  @el.classList.add('hide')

v.set 'show', ->
  @el.classList.remove('hide')

module.exports = v.make()
