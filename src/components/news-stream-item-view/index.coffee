
ReleaseThumbnailView = require("release-thumbnail-view")
View = require("view-plugin")

v = bQuery.view()

v.use View
  className: "news-stream-item-view"
  template: require("./template")

v.init (opts={})->
  { @label, @scrollTarget, @router } = opts
  @thumb = @model.get("thumb")

  @thumbnail = new ReleaseThumbnailView
    scrollTarget: @scrollTarget
    size: "80px" # src image size set in news-stream-collection
    src: @thumb

v.set "render", ->
  @renderer.render()

  @el.querySelector(".content").classList.add(@model.get("kind").toLowerCase())

  if @thumb isnt undefined
    @thumbnail.appendTo(@el.querySelector(".thumb"))
    @thumbnail.render()

module.exports = v.make()