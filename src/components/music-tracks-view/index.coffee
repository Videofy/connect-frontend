table = require("music-tracks-table-plugin")
view  = require("view-plugin")

MusicTracksView = v = bQuery.view()

v.use view
  className: "music-tracks-view music-catalog-view"
  template: require("./template")

v.use table
  filter: (release, track)->
    return no if release.get('type') is "Podcast"
    release.isTrackReleased(track)

  getSort: (oldKey, newKey)->
    if newKey is 'release'
      return ['release', 'number']
    else if newKey
      return [newKey]
    ['date', 'release', 'number']
  trackerName: "MusicTracksView"

module.exports = v.make()