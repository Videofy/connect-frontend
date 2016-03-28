ReleaseCollection = require('release-collection')
view              = require("view-plugin")

TrackReleasesView = v = bQuery.view()

v.use view
  className: "track-releases-view"
  template: require("./template")

v.init (opts={})->
  throw Error("No model.") unless @model and @model.id
  @collection = new ReleaseCollection null, fields: [
    'title',
    'releaseDate',
    'catalogId',
    'type']

v.set "render", ->
  return if @renderer.locals.mode is 'loading'
  @renderer.locals.mode = 'loading'
  @renderer.render()
  @model.toPromise().then =>
    @collection.list = @model.get('albums').map (album)-> album.albumId
    @collection.sfetch (err, col)=>
      @renderer.locals.mode = if err then 'error' else 'view'
      @renderer.render()

module.exports = v.make()
