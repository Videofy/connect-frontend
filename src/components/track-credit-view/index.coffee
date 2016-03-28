View = require("view-plugin")

TrackCreditView = v = bQuery.view()

v.use View
  className: "track-credit-view"
  template: require("./template")

v.init (opts={})->
  @renderer.locals.text = opts.text

v.set "render", ->
  @renderer.render()

v.set "focus", (delay=16)->
  setTimeout =>
    textarea = @n.getEl("[role='copy']")
    textarea.focus()
    textarea.select()
  , delay

module.exports = v.make()
