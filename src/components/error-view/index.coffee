view = require('view-plugin')

ErrorView = v = bQuery.view()

v.use view
  className: 'error-view'
  template: require('./template')

v.set 'render', ->
  @renderer.render()

module.exports = v.make()