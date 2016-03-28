SliderView = require("slider-view")
View = require("view-plugin")

low = 0.07
high = 0.9

wrap = (percent)->
  return 0 if percent < low
  return 1 if percent > high
  percent

onSlideMove = (percent)->
  @update(wrap(percent))

onSlideEnd = (percent)->
  percent = wrap(percent)
  @update(percent)
  @player.volume(percent)

onClickStatus = (e)->
  percent = if @player.vol is 0 then 1 else 0
  @update(percent)
  @player.volume(percent)

VolumeView = v = bQuery.view()

v.use View
  className: "volume-view"
  template: require("./template")

v.ons
  "click [role='status']": onClickStatus

v.init (opts={})->
  { @player } = opts
  @slider = new SliderView()
  @slider.on("slidemove", onSlideMove.bind(@))
  @slider.on("slideend", onSlideEnd.bind(@))

v.set "render", ->
  @renderer.render()
  @slider.render()
  @el.insertBefore(@slider.el, @el.firstChild)

v.set "update", (percent)->
  icon = @el.querySelector("[role='status']")
  @n.evaluateClass(icon, "fa-volume-up", percent >= 0.5)
  @n.evaluateClass(icon, "fa-volume-down", percent < 0.5 and percent > low)
  @n.evaluateClass(icon, "fa-volume-off", percent <= low)
  @slider.setPosition(percent)

module.exports = v.make()
