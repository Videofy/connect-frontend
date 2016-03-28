SliderView = require("slider-view")
View = require("view-plugin")

SeekerView = v = bQuery.view()

v.use View
  className: "seeker-view"

v.init (opts={}) ->
  { @player } = opts
  @slider = new SliderView()
  @slider.on("slideend", @onSlideEnd.bind(@))

v.set "render", ->
  @slider.render()
  @el.appendChild(@slider.el)

v.set "watch", ->
  return if @timer isnt undefined
  @timer = setTimeout(@onStep.bind(@), 16.67)

v.set "unwatch", ->
  clearTimeout(@timer)
  delete @timer

v.set "onStep", ->
  percent = 0
  if @player.audio
    percent = @player.audio.currentTime / @player.audio.duration
  @slider.setPosition(percent)
  @timer = setTimeout(@onStep.bind(@), 16.67)

v.set "onSlideEnd", (percent)->
  @player.seek(percent)

module.exports = v.make()