onClickRow = (e)->
  return if not @pane
  if not @pane.rendered
    @pane.rendered = true
    @pane.render()

  @pane.el.classList.toggle('hide')

module.exports = (v)->
  v.init (opts={})->
    { @pane } = opts
    @pane?.el.classList.add('hide')

  v.ons
    "click": onClickRow
