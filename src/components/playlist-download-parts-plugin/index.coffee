PresenterView                 = require("presenter-view")
PlaylistDownloadPartsView     = require('playlist-download-parts-view')

module.exports = (config={})-> (v)->
  v.init (opts={})->
    @downloadPartsPresenter = new PresenterView
    @downloadPartsPresenter.el.classList.add("playlist-download-parts", "flexi")
    @on "render", => @downloadPartsPresenter.attach()  

  v.set "openDownloadParts", (formatType, formatQuality, playlist)->
    view = new PlaylistDownloadPartsView({playlist: playlist, formatType: formatType, formatQuality: formatQuality})
    view.render()
    @downloadPartsPresenter.open(view)    