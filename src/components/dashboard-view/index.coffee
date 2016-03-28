CollectionViewListing       = require("collection-view-listing")
CollectionViewListingFilter = require("collection-view-listing-filter")
NewsStreamItemView          = require("news-stream-item-view")
sortutil                    = require("sort-util")
View                        = require("view-plugin")

DashboardView = v = bQuery.view()

v.use View
  className: "dashboard-view"
  template: require("./template")

v.init (@opts={})->
  @collection.fetchIfNew()

v.set "render", ->
  @renderer.render()
  @listing?.off()
  @listing = new CollectionViewListing
    collection: @collection
    el: @el.querySelector("[role='news-stream']")

    createViewsForModel: ( model ) =>
      @opts.model = model
      return view =
        default: new NewsStreamItemView(@opts)

    compareModels: ( a, b ) =>
      da = a.get("date")
      db = b.get("date")
      sortutil.dateStrings(da, db)

  @listingFilter = new CollectionViewListingFilter
    listing: @listing
    filterProperty: "kind"
    selectEl: @el.querySelector("[role='filter']")
    strings:
      filterTypes: @i18.strings.defaults.all
  @updateFilterTypes()

v.set "updateFilterTypes", ->
  return if !@listingFilter
  kinds = []
  for kind in ["File", "Album"]
    kinds.push
      name: @i18.strings.newsStreamKinds[kind]
      value: kind
  @listingFilter.setTypes(kinds)

module.exports = v.make()
