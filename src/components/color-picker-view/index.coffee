
ColorPicker = require("color-picker")
TemplateRenderer = require("template-renderer")

class View extends Backbone.View

  className: "color-picker-view"

  initialize: ( opts={} ) ->
    @renderer = new TemplateRenderer
      view: @
      template: require("./template")
    if opts.autoclose
      @autocloseListener = @onDocumentClick.bind(@)

  render: ->
    @renderer.render()
    if @cp
      @cp.off()
      @cp.remove()
      delete @cp
    @cp = new ColorPicker
    @cp.on("change", @onColorChange.bind(@))
    @cp.appendTo(@el)
    if @autocloseListener
      document.addEventListener "click", @autocloseListener

  remove: ->
    Backbone.View.prototype.remove.apply(this, arguments)
    @cp.off()
    @cp.remove()
    delete @cp
    if @autocloseListener
      document.removeEventListener "click", @autocloseListener

  position: ( top, right, bottom, left ) ->
    if top?
      @el.style.top = top
    else
      delete @el.style.top
    
    if right?
      @el.style.right = right
    else
      delete @el.style.right

    if bottom?
      @el.style.bottom = bottom
    else
      delete @el.style.bottom

    if left?
      @el.style.left = left
    else
      delete @el.style.left

  onColorChange: ( color ) ->
    @trigger("colorchange", color)

  onDocumentClick: ( e ) ->
    if @cp
      needle = @cp.el
      el = e.target
      result = false
      
      while el
        if el == needle
          result = true
          break;
        el = el.parentElement

      if not result
        @remove()

module.exports = View
