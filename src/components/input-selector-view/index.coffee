Enabler = require("enabler")
TemplateRenderer = require("template-renderer")

class InputSelectorView extends Backbone.View

  className: "input-selector-view"

  initialize: ( opts={} ) ->
    { @multiples, @strict, @placeholder, @notnull, @disabled, @property, @callback } = opts
    @renderer = new TemplateRenderer
      view: @
      template: require("./template")
      locals:
        title: @placeholder
        placeholder: @placeholder
    @n = new Enabler(@el)
    @choices = {}
    @value = []

  render: ->
    @renderer.render()
    @n.evaluateClass(null, "disabled", @disabled)
    input = @n.getEl("input")
    input.disabled = @disabled
    clickbind = @onElClick.bind(@)
    input.addEventListener("keyup", @onInputKeyUp.bind(@))
    input.addEventListener("click", clickbind)
    input.addEventListener("blur", @onInputBlur.bind(@))
    @el.querySelector(".c-open").addEventListener("click", clickbind)
    @el.querySelector(".c-close").addEventListener("click", @onCloseClick.bind(@))
    @renderChoices()
    @updateValue()

  renderChoices: ->
    el = @el.querySelector(".choices")
    if !el
      return

    el.innerHTML = ""
    for k, v of @choices
      li = document.createElement("li")
      li.textContent = v
      li.setAttribute("data-value", k)
      li.addEventListener("click", @onClickChoice.bind(@))
      el.appendChild(li)

  clear: ->
    @value = []
    @revertValue()

  save: ( value ) ->
    if !@multiples and value instanceof Array
      value = value[0]

    if @callback
      @callback(value, @value)

    @value = value

    if @model and @property
      config = {}
      config[@property] = value
      @model.save(config, patch: true)

  setChoices: ( value ) ->
    @choices = value
    @renderChoices()

  revertValue: ->
    input = @el.querySelector("input")
    if not input
      return

    val = @value or []
    if typeof val is "string"
      val = [val]

    txts = []
    for v, i in val
      txts.push(@choices[v] or v)

    input.value = txts.join(", ")
    input.blur()

  updateValue: ->
    input = @el.querySelector("input")
    if not input
      return

    vals = []
    txts = []

    val = input.value
    if @multiples
      val = val.split(",")
    else
      val = [val]

    for text, i in val
      text = text.trim()
      if @strict
        pushed = false
        for key, value of @choices
          if text is value and vals.indexOf(key) is -1
            pushed = true
            vals.push(key)
            txts.push(value)
            break
        if !pushed and text.length > 0
          for key, value of @choices
            if value.indexOf(text) > -1 and vals.indexOf(key) is -1
              vals.push(key)
              txts.push(value)
              break
      else if vals.indexOf(text) is -1
        vals.push(text)
        txts.push(text)

    if @notnull and vals.length is 0
      return @revertValue()

    input.value = txts.join(", ")
    @save(vals)

  setSingleValueFromChoice: ( key ) ->
    value = @choices[key]
    if not value
      return

    @save(key)
    @revertValue()
    @displayChoices(false)

  addValueFromChoice: ( key ) ->
    value = @choices[key]
    if not value
      return

    input = @el.querySelector("input")
    input.value += ", " + value
    @updateValue()
    input.focus()

  removeFocus: ->
    @el.querySelector("input").blur()

  displayChoices: ( value ) ->
    @n.evaluateClass(".choices", "hide", !value)
    @n.evaluateClass(".c-close", "hide", !value)
    @n.evaluateClass(".c-open", "hide", value)

  disable: ( value ) ->
    @disabled = !!value
    input = @el.querySelector("input")
    if input
      input.disabled = @disabled 

  onInputKeyUp: ( e ) ->
    if @disabled
      return

    el = e.currentTarget
    code = e.keyCode

    if code is 27
      @revertValue()
      @removeFocus()
      @displayChoices(false)
    else if code is 13
      @updateValue()
      @removeFocus()
      @displayChoices(false)

  onInputBlur: ( e ) ->
    @revertValue()

  onElClick: ( e ) ->
    if @disabled
      return

    @displayChoices(true)

  onClickChoice: ( e ) ->
    if @disabled
      return

    e.preventDefault()
    e.stopPropagation()
    el = e.currentTarget
    value = el.getAttribute("data-value")
    if !@multiples
      @setSingleValueFromChoice(value)
    else
      @addValueFromChoice(value)

  onCloseClick: ( e ) ->
    if @disabled
      return

    e.stopPropagation()
    @updateValue()
    @displayChoices(false)

module.exports = InputSelectorView
