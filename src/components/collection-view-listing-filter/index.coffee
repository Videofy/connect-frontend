
class CollectionViewListingFilter

  constructor: ( opts ) ->
    @listing = opts.listing
    @filterProperty = opts.filterProperty
    @selectEl = opts.selectEl
    @predicate = opts.predicate
    @predicateType = opts.predicateType

    strings = opts.strings || {}
    @strings =
      filterTypes: strings.filterTypes || "Filter Types"

  setTypes: ( types, allOption=true ) ->
    while @selectEl.firstChild
      @selectEl.removeChild(@selectEl.firstChild)

    if allOption
      types.splice(0, 0, { name: @strings.filterTypes, value: "" })

    for type in types
      option = document.createElement("option")
      if type.disabled then option.setAttribute("disabled", "") else option.setAttribute("value", type.value)
      option.setAttribute("selected", "") if type.selected
      option.innerHTML = type.name || type.value
      @selectEl.addEventListener "change", @onClickFilter.bind(@)
      @selectEl.appendChild(option)

  setCurrentType: ( type ) ->
    if @currentFilter
      @listing.removePropertyFilter @filterProperty, @currentFilter
      delete @currentFilter

    if type? and type isnt ""
      @currentFilter = (value, model)=>
        if @predicate
          return @predicate(value, type, model)
        value != type
      @listing.addPropertyFilter @filterProperty, @currentFilter

    @listing.sift(@listing.needle)

  onClickFilter: ->
    type = @selectEl.options[@selectEl.selectedIndex].value
    type = @predicateType?(type) or type
    @setCurrentType(type)

module.exports = CollectionViewListingFilter
