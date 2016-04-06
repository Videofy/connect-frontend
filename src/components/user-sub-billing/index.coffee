view = require("view-plugin")
eurl = require("end-point").url
v = bQuery.view()

v.init (opts={})->
  { @i18 } = opts

v.use view
  className: "user-payments-view"
  template: require("./template")
  locals:
    eurl: eurl

v.set "render", ->
  @renderer.locals.mode = 'loading'
  @renderer.render()
  @collection.sfetch (err, col)=>
    if err
      @renderer.locals.mode = 'error'
      @renderer.locals.error = err.message
    else
      @renderer.locals.mode = 'view'
    @renderer.render()

module.exports = v.make()
