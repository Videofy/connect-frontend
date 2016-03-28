lens = require('dot-lens')

# TODO Move to utility.
oclock = (date, hour)->
  date = new Date(date)
  date.setHours(hour)
  date.setMinutes(0)
  date.setSeconds(0)
  date.setMilliseconds(0)
  date

isExpected = (expected)-> (value)->
  value == expected

onChangeFilter = (e)->
  needle = e.currentTarget.value
  @setFilter(needle)
  @renderRows()

onChangeSort = (e)->
  el = e.currentTarget
  prop = el.getAttribute('sort-on')
  mode = el.getAttribute('order')

  if not mode
    mode = 'asc'
  else if mode is 'asc'
    mode = 'desc'
  else
    mode = ''
    prop = ''

  if cel = @currentSortEl
    cel.classList.remove('active')
    cel.classList.remove('asc')
    cel.classList.remove('desc')
    cel.removeAttribute('order')

  el.classList[if mode then 'add' else 'remove']('active')
  if mode
    el.classList.add(mode)
    el.setAttribute('order', mode)
  @currentSortEl = el
  @setSort(prop, mode)
  @renderRows()

onClickNext = (e)->
  @setRange(@range.start + @range.increment, @range.increment)
  @renderRows()

onClickPrevious = (e)->
  @setRange(@range.start - @range.increment, @range.increment)
  @renderRows()

onChange = ->
  @setRange(@range.start, @range.increment)
  @renderRows()

module.exports = (config)->
  selectFilter = config.selectFilter || {}

  updateFilter = (el)->
    prop = el.getAttribute('filter')
    value = el.value

    if config.interceptFilterValue?
      value = config.interceptFilterValue(el, prop, value)

    if not value?
      delete @filters[prop]
    else if selectFilter[prop]
      @filters[prop] = config.selectFilter[prop](value)
    else
      @filters[prop] = isExpected(value)

  onClickFilter = (e)->
    updateFilter.call(@, e.currentTarget)
    @renderRows()

  (v)->

    v.ons
      'keyup [role="filter"]': onChangeFilter
      'click [sort-on]': onChangeSort
      'click [role="page-previous"]': onClickPrevious
      'click [role="page-next"]': onClickNext
      'change [filter]': onClickFilter

    v.init (opts={})->
      throw Error('collection was not provided.') unless @collection
      throw Error('setFilter method not set.') unless @setFilter
      throw Error('setSort method not set.') unless @setSort
      throw Error('setRange method not set.') unless @setRange
      @filters = {}
      @setFilter()
      @setSort()
      @setRange()
      @listenTo(@collection, 'add reset remove', onChange.bind(@))

    v.set 'renderRows', ->
      @collection.toPromise().then =>
        opts =
          sort: @sort
          filter: @filter
          range: @range

        if config.renderRows?
          @updatePagination() if config.renderRows.call(@, opts)
        else if config.rowsTemplate?
          return unless tbody = @n.getEl('tbody')
          tbody.innerHTML = config.rowsTemplate
            models: @collection.getPage(opts)
            permissions: @permissions
          @updatePagination()

    v.set "updatePagination", (view)->
      return unless @n.getEl('.table-pagination')

      { range } = @

      @n.evaluateClass('.table-pagination', 'no-pages',
        !range.total or (range.start is 0 and
        range.start + range.increment >= range.total))
      @n.evaluateDisabled('[role="page-previous"]', range.start <= 0)
      @n.evaluateDisabled('[role="page-next"]',
        range.start + range.increment >= (range.total or 0))

      text = "No Results"
      total = range.total
      if total > 0
        start = range.start + 1
        end = range.start + range.increment
        end = total if end > total
        text = "#{start} - #{end} of #{total}"

      @n.setText('[role="page-next"] [role="increment"]', range.increment)
      @n.setText('[role="page-previous"] [role="increment"]', range.increment)
      @n.setText('[role="results"]', text)

    v.set 'updateFilters', ->
      els = Array.prototype.slice.call(@el.querySelectorAll('[filter]'))
      els.forEach (el)=>
        updateFilter.call(@, el)

module.exports.createPropertyFilter = (filters)->
  (model)=>
    for key, filter of filters
      continue unless filter?
      return false unless filter(model.get(key), model)
    true

module.exports.createFilter = (needle, properties, dateField='date')->
  unless needle
    return -> true

  date = oclock(new Date(needle), 0)
  date = undefined if isNaN(date.valueOf())
  rx = new RegExp(".*" + needle + ".*", "i")
  dots = properties.map (property)-> lens(property)
  (model)->
    obj = model.attributes
    return yes if date and obj[dateField] and
      oclock(obj[dateField], 0).valueOf() == date.valueOf()
    for dot in dots
      try
        str = dot.get(obj)
      catch e
        continue
      return yes if rx.test(str)
    no
