module.exports =

  genre:
    colorizeEl: (el) ->
      style = "4px solid #{ @genreColor() }"
      el.style["border-left"] = style

    genreColor: ->
      genre = @get('genres')?[0]
      require('genre-colors')[genre]

  misc:
    displayTitle: ->
      "#{ @get('artistsTitle') } - #{ @get('title')}"

  highestTrack: ->
    nums = @models.map (m) => m.get("trackNumber")
    module.exports.getHighestTrack(nums)

  getHighestTrack: (ts) ->
    return 0 if ts.length is 0
    Math.max.apply null, (t or 0 for t in ts)

