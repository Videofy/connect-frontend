view = require("view-plugin")

TrackContractsView = v = bQuery.view()

v.use view
  className: "track-contracts-view"
  template: require("./template")

v.set "render", ->
  @renderer.locals.mode = 'loading'
  @renderer.render()
  @collection.toPromise().then =>
    @renderer.locals.mode = 'view'
    @renderer.render()

module.exports = v.make()
