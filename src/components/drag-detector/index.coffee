
class DragDetector

  constructor: (@zone, @target, classname="dragging")->
    leave = (e)=>
      @target.classList.remove(classname)
    enter = (e)=>
      @target.classList.add(classname)
    @cbs =
      "dragenter": enter
      "dragleave": leave
      "drop": leave
  listen: ->
    for k, v of @cbs
      @zone.addEventListener(k, v)

  stopListening: ->
    for k, v of @cbs
      @zone.removeEventListener(k, v)

module.exports = DragDetector
