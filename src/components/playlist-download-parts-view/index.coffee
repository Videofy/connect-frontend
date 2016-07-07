View 					= require("view-plugin")
PlaylistModel 			= require("playlist-model")

PlaylistDownloadPartsView = v = bQuery.view()

v.use View
  className: "playlist-download-parts-view"
  template: require("./template")

v.init (opts={})->
  links = []
 	for i in [1.. opts.playlist.downloadParts]
 		start = (i - 1) * PlaylistModel.tracksPerDownloadPart + 1
 		end = Math.min(start + PlaylistModel.tracksPerDownloadPart - 1, opts.playlist.get('tracks').length)
 		links.push
 			url: opts.playlist.downloadUrl(opts.formatType, opts.formatQuality, i)
 			name: "Part #{i}"
 			subtitle: "Tracks " + start + ' to ' + end

  @renderer.locals.playlist = opts.playlist
  @renderer.locals.formatType = opts.formatType
  @renderer.locals.formatQuality = opts.formatQuality
  @renderer.locals.links = links

v.set "render", ->
  @renderer.render()

module.exports = v.make()
