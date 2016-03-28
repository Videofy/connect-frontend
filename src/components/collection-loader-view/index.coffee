
Enabler = require("enabler")
TemplateRenderer = require("template-renderer")

class CollectionLoaderView extends Backbone.View

  className: "collection-loader-view"

  initialize: ( opts ) ->
    @n = new Enabler(@el)
    @renderer = new TemplateRenderer
      view: @
      template: require("./template")
    @collection.on "request", @onRequestStart.bind(@)
    @collection.on "sync error", @onRequestFinish.bind(@)

  render: ->
    @renderer.render()
    if @collection.isFetching
      @display(@collection.isFetching())

  display: ( visible ) ->
    return if !@el.firstChild
    @n.evaluateClass(".ss-loader", "hide", !visible)

  onRequestStart: ->
    @display(true)

  onRequestFinish: ->
    @display()

module.exports = CollectionLoaderView
