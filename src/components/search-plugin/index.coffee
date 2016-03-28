SearchView = require('./view')
point      = require('point')

beginsWith = (model, props, prefix)->
  prefix = prefix.toLowerCase()
  for prop in props
    lower = if model.get then model.get(prop)?.toLowerCase?() else model[prop]?.toLowerCase?()
    return false if not lower
    return true if lower.indexOf(prefix) is 0
  false

findIn = (collection, props, prefix)->
  props = [props] if typeof props is 'string'
  return [] if not props.length
  models = collection.models || collection
  return models.filter (model)->
    beginsWith(model, props, prefix)

plugin = (config)->
  { rowsTemplate, target, prompt, empty } = config

  throw Error('target was not provided.') unless target
  throw Error('getItems method was not provided.') unless config.getItems

  (v)->

    getArrowSelection = ->
      @svMap[target].el.querySelectorAll('li')[@svMap[target].selectedIndex]

    clearArrowSelection = ->
      for item in @svMap[target].el.querySelectorAll('li')
        item.classList.remove('selected')
      delete @svMap[target].selectedIndex

    selectItem = (el)->
      @svMap[target].hide()
      value = el.getAttribute('value')
      config.select?.call(@, value)
      @n.getEl("#{target} input").value = el.innerHTML
      @svMap[target].value = value
      clearArrowSelection.call(@)

    onChange = (e)->
      @svMap[target].showLoading()
      clearArrowSelection.call(@)

      if not e.currentTarget.querySelector('input').value
        @svMap[target].showPrompt()
      else
        config.getItems.call @, e.currentTarget.querySelector('input').value, (arr)=>
          @svMap[target].setResults(arr)

    onKeydown = (e)->
      index = if @svMap[target].selectedIndex? then @svMap[target].selectedIndex else -1
      if e.keyCode is 40
        index++
      else if e.keyCode is 38
        index--
      else if e.keyCode is 13 and selection = getArrowSelection.call(@)
        return selectItem.call(@, selection)
      else
        return

      items = e.currentTarget.querySelectorAll('li')
      return if not items.length

      clearArrowSelection.call(@)
      index = point.clamp(index, 0, items.length - 1)
      @svMap[target].selectedIndex = index

      container = e.currentTarget.querySelector('.search-results-view')
      container.scrollTop = items[index].offsetTop - container.offsetHeight / 2

      items[index].classList.add('selected')

    onFocus = (e)->
      @svMap[target].showPrompt()

    onBlur = (e)->
      @svMap[target].hide()

    onSelectItem = (e)->
      selectItem.call(@, e.currentTarget)

    render = ->
      @svMap[target].render()
      @n.getEl(target)?.appendChild(@svMap[target].el)

    v.init ->
      @on 'render', render.bind(@)

      view = new SearchView
        prompt: prompt
        empty: empty

      @svMap = @svMap || {}
      @svMap[target] = view

    v.on "input #{target}", onChange
    v.on "focus #{target} input", onFocus
    v.on 'mousedown [role="item"]', onSelectItem
    v.on "blur #{target} input", onBlur
    v.on "keydown #{target}", onKeydown

    v.set 'getSearchInputValue', (target)->
      @svMap[target].value

    v.set 'resetSearchInputValue', (target)->
      delete @svMap[target].value

plugin.searchCollection = findIn

module.exports = plugin
