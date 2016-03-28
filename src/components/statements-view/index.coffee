CollectionViewListing = require("collection-view-listing")
TemplateRenderer = require("template-renderer")
StatementRowView = require("statement-row-view")

onListingSifted = ->
  text = @i18.strings.phrases.displayingResults
  text = text.replace(/%i/, @listing.getNumResultsDisplaying())
  text = text.replace(/%i/, @listing.getNumResults())
  @el.querySelector("[role='results-count']").innerHTML = text

class StatementsView extends Backbone.View

  className: "statements-view"

  initialize: ( opts ) ->
    @i18 = opts.i18
    @renderer = new TemplateRenderer
      view: @
      template: require("./template")
      locals:
        collection: @collection
        strings: @i18.strings

  render: ->
    @renderer.locals.mode = 'loading'
    @renderer.render()
    @collection.toPromise().then =>
      @renderIt()
      onListingSifted.call(@)

  renderIt: ->
    @renderer.locals.mode = 'view'
    @renderer.render()
    if @listing
      @listing.off()
    @listing = new CollectionViewListing
      collection: @collection
      el: @el.querySelector("table > tbody")
      inputEl: @el.querySelector("[role='filter']")
      moreEl: @el.querySelector("[role='more']")
      createViewsForModel: ( model ) =>
        views =
          default: new StatementRowView
            model: model
            i18: @i18
      compareModels: ( a, b ) =>
        ad = new Date(Date.parse(a.get("createdDate")))
        bd = new Date(Date.parse(b.get("createdDate")))
        if ad > bd
          return -1
        else if ad < bd
          return 1
        0
      siftModel: ( model, needle ) =>
        if model.get("filename").toLowerCase().indexOf(needle.toLowerCase()) < 0
          return true
        return false
    @listing.on "sifted", onListingSifted.bind(@)

module.exports = StatementsView