module.exports.tracks = (tracks)->
  txt = "#{tracks.length} Track"

  if tracks.length > 1
    txt += "s"
  else if tracks.length is 1
    txt += " (#{tracks[0].track.attributes.title})"

  cvs = document.createElement("canvas")
  cvs.width = 800
  ctx = cvs.getContext("2d")
  ctx.fillStyle = "black"
  ctx.font = "10pt proxima-nova"
  ctx.textBaseline = "top"
  ctx.fillText(txt, 0 , 0)

  img = document.createElement("img")
  img.src = cvs.toDataURL()
  img
