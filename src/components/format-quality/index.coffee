module.exports = (format, quality)->
  query =
    format: format

  if quality?
    quality = parseInt(quality)
    if quality >= 10
      query.bitRate = quality
    else
      query.quality = quality

  query