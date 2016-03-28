
inViewport = require("in-viewport")

class ReleaseThumbnailView extends Backbone.View

  className: "release-thumbnail-view"

  initialize: ( opts ) ->
    @scrollTarget = opts.scrollTarget or window
    @size = opts.size
    @source = opts.src or opts.source
    @default = opts.default or @defaultImage()
    @img = new Image()
    @listeners =
      load: @onLoad.bind(@)
      error: @onError.bind(@)
      check: @watch.bind(@)

  defaultImage: (size=@size) ->
    ratio = if window.devicePixelRatio > 1 then 2 else 1
    retina = if ratio is 2 then "@2x" else ""
    if size is 32
      url = "/img/defaultArtSmall#{ retina }.png" if size is 32
    else
      url = "/img/defaultArt#{ retina }.png"

  render: ->
    @el.style.width = @size
    @el.style.height = @size
    @el.appendChild(@img)

  remove: ->
    Backbone.View.prototype.remove.apply(this, arguments)
    @unwatch()

  watch: ->
    @unwatch()

    if not @alive
      contained = document.contains(@el)

      if not contained
        @timer = setTimeout(@listeners.check, 500)
      else if contained and not inViewport(@el, 200)
        @scrollTarget.addEventListener("scroll", @listeners.check)
      else
        @alive = true
        @setImage(@source)

  unwatch: ->
    if @timer
      clearTimeout(@timer)
      delete @timer
    @scrollTarget.removeEventListener("scroll", @listeners.check)

  appendTo: ( el ) ->
    el.appendChild(@el)
    @watch()

  setImage: ( source ) ->
    @clean()
    @img.addEventListener("load", @listeners.load)
    @img.addEventListener("error", @listeners.error)
    @img.src = @current = source

  clean: ->
    @img.removeEventListener("load", @listeners.load)
    @img.removeEventListener("error", @listeners.error)

  onLoad: ( e ) ->
    @clean()

  onError: ( e ) ->
    if @current != @default
      @setImage(@default)

module.exports = ReleaseThumbnailView
