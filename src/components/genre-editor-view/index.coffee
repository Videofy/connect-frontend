
Color = require("color")
ColorPickerView = require("color-picker-view")
ElementModelBinder = require("element-model-binder")
TemplateRenderer = require("template-renderer")

class GenreEditorView extends Backbone.View

  className: "genre-editor-view form-inline"

  events:
    "click .color-block": "onClickColorBlock"

  initialize: ( opts ) ->
    @genre = opts.genre
    @renderer = new TemplateRenderer
      view: @
      template: require("./template")
      locals:
        genre: @genre
    @binder = new ElementModelBinder
      get: ( prop ) =>
        @genre[prop]
      set: ( prop, value ) =>
        @genre[prop] = value
      save: =>
        @setColor(@genre.color, false)
        @trigger("change", @)

  render: ->
    @renderer.render()
    @binder.reset()
    @binder.bindBatch [
      el: @el.querySelector("input.genre-name")
      property: "name"
    ,
      el: @el.querySelector("input.genre-color")
      property: "color",
      value: ( el ) =>
        if !Color.validHex(el.value)
          return @genre.color
        return el.value
    ]
    @colorblock = @el.querySelector(".color-block")
    @colorinput = @el.querySelector("input.genre-color")

  setColor: ( hex, save ) ->
    @colorblock.style.backgroundColor = "##{hex}"
    @colorinput.value = hex.toUpperCase()
    if save
      @genre.color = hex
      @trigger("change", @)

  onClickColorBlock: ( e ) ->
    e.stopPropagation()
    cpv = new ColorPickerView
      autoclose: true
    cpv.render()
    cpv.position("-80px", "-235px")
    cpv.on "colorchange", @onColorChange.bind(@)
    @el.appendChild(cpv.el)

  onColorChange: ( color ) ->
    @setColor(color.toHex(false), false)
    if @timer
      clearTimeout(@timer)
      delete @timer
    @timer = setTimeout =>
      @setColor(color.toHex(false), true)
    , 200

module.exports = GenreEditorView
