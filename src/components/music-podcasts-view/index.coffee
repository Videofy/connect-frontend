MusicTracksTable = require("music-tracks-table-plugin")
View = require("view-plugin")

MusicPodcastsView = v = bQuery.view()

v.use View
  className: "music-podcasts-view music-tracks-view"
  template: require("./template")

v.use MusicTracksTable
  filter: (release, track)->
    return true if release.attributes.type is "Podcast"
    false
  getSort: (oldKey, newKey)->
    return [newKey] if newKey
    ["date"]
  trackerName: "MusicPodcastsView"

module.exports = v.make()
