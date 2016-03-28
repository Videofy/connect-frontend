view = require("view-plugin")

StatusView = v = bQuery.view()

v.use view
  className: "status-view"
  template: require("./template")

v.init (opts={})->
  { @getErrors } = opts

v.set "render", ->
  return if @renderer.locals.mode is 'loading'
  @renderer.locals.mode = 'loading'
  @renderer.render()
  @stopListening(@model)
  @listenTo(@model, "change", @render.bind(@))
  @getErrors (err, errors)=>
    if err
      @renderer.locals.mode = 'error'
      @renderer.locals.error = err.message
      return
    @renderer.locals.mode = 'view'
    @renderer.locals.errors = errors or []
    @renderer.render()

module.exports = v.make()
