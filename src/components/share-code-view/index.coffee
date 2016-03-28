view = require("view-plugin")
v    = bQuery.view()

v.use view
  className: "share-code-view"
  template: require("./template")

v.init (opts={})->

v.set "render", ->
  @renderer.render()

module.exports = v.make()
