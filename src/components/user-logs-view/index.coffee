view = require("view-plugin")

v = bQuery.view()

v.use view
  className: 'user-logs-view'
  template: require("./template")

v.set "render", ->
  @collection.fetchIfNew ()=>
    @renderer.render()

module.exports = v.make()
