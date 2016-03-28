formatdate = require('date-time').format

class InputBinder

  constructor: ( @el, @model, @mode='save') ->
    throw Error('Element not provided.') unless @el
    throw Error('Model not provided.') unless @model
    @cache = []

  reset: ->
    while @cache.length
      item = @cache[0]
      @unbind(item.selector, item.property, item.event)

  findAndBind: ( attribute="property" ) ->
    @reset()
    els = Array.prototype.slice.call(@el.querySelectorAll("[#{attribute}]"))
    while els.length
      el = els.shift()
      @bind(el, el.getAttribute(attribute))

  getEl: ( selector ) ->
    if not selector
      return @el
    else if selector.tagName
      return selector
    return @el.querySelector(selector)

  bind: ( selector, property, event ) ->
    el = @getEl(selector)
    return if not el
    tag = el.tagName.toLowerCase()
    type = el.type

    if not event and type is "checkbox"
      event = "click"
    else if not event
      event = "change"

    updateElementValue = =>
      prop = @model.get(property)
      if tag is 'select'
        Array.prototype.slice.call(el.options).forEach (option, index)->
          el.selectedIndex = index if option.value is prop
      else if type is "checkbox"
        el.checked = !!prop
      else if type is "radio"
        el.checked = prop is el.value
      else if type is "date"
        el.value = if prop? then formatdate('Y-m-d', new Date(prop)) else undefined
      else
        el.value = prop or ''

    @model.on "change:#{property}", updateElementValue

    ###
    TODO
    Too much UI dictation.
    Remove the paragraph and just dispatch events instead.
    ###
    p = document.createElement("p")
    p.className = "ss msg error"

    elCallback = =>
      config = {}
      value = el.value
      if type is "checkbox"
        value = el.checked
      else if type is "date"
        value = new Date(value.replace('-', '/'))
      config[property] = value

      if @mode is 'save'
        @model.save config,
          patch: true
          success: ( model, res, opts ) =>
            el.classList.remove("error")
            p.remove()
          error: ( model, res, opts ) =>
            el.classList.add("error")

            try
              data = JSON.parse(res.responseText)
              data = if data.error then data.error else {}
              message = data.errors?[property]?.message or data.message
            catch e
              message = undefined

            if message and !el.getAttribute("errornone")
              p.textContent = message

              tel = el
              numParents = parseInt(el.getAttribute("errorparent"))
              while numParents
                numParents--
                tel = tel.parentElement
              tel.parentElement.insertBefore(p, tel)
            else
              p.remove()

      else if @mode is 'set'
        @model.set(config)

    el.addEventListener event, elCallback

    @cache.push
      selector: selector
      property: property
      event: event
      elCallback: elCallback
      propCallback: updateElementValue

    updateElementValue()

  unbind: ( selector, property, event="change" ) ->
    el = @getEl(selector)
    return if not el

    for v, i in @cache
      if v.selector is selector and v.property is property and v.event is event
        el.removeEventListener(event, v.elCallback)
        @model.off "change:#{property}", v.propCallback
        @cache.splice(i, 1)
        break

module.exports = InputBinder
