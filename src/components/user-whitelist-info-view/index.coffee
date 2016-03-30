datetime    = require("date-time")
view        = require('view-plugin')

UserWhitelistBodyView = v = bQuery.view()

v.use view
  template: require('./template')

v.init (opts={})->
  { @subscription } = opts

v.set 'render', ->
  @renderer.locals.mode = 'loading'
  @renderer.locals.subscription = @subscription
  @renderer.locals.fmtdt = datetime
  @renderer.render()
  @model.sfetch (err)=>
    if err
      @renderer.locals.mode = 'error'
      @renderer.locals.error = err.message
      @renderer.render()
      return
    @renderer.locals.mode = 'view'
    @renderer.render()

module.exports = v.make()
