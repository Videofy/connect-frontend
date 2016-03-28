ReleaseModel = require('release-model')
SuperModel = require('super-model')
SuperCollection = require('super-collection')

class NewsStreamCollection extends SuperCollection

  urlRoot: "/dashboard/stream"

  parse: (res, opts) ->
    _(res).map (entry) =>
      @setModelForEntry(entry)

  setModelForEntry: ( entry ) ->
    kind = (entry.kind or "").toLowerCase()
    model = new SuperModel

    switch kind
      when "album"
        release = new ReleaseModel(entry)
        release.set("labelName", @label.get("name"))
        release

        model.set {
          date: release.get("releaseDate")
          kind: release.get("kind")
          link: "/#music/#{release.get("_id")}"
          text: release.get("renderedArtists")
          thumb: release.coverUrl(128, @label.get("name"))
          title: release.get("title")
          type: release.get("type")
        }
      when "file"
        model.set {
          date: entry.mtime
          kind: entry.kind
          link: "/#handbook/blog/#{entry.link}"
          text: entry.content
          thumb: entry.image
          title: entry.title
          type: entry.type
        }

    return model

module.exports = NewsStreamCollection
