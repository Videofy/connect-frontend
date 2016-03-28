view = require('view-plugin')

v = bQuery.view()

v.use view
  className: 'user-articles-view'
  template: require('./articles-template')

v.set 'render', ->
  @collection.toPromise(true).then =>
    @renderer.render()

module.exports = v.make()