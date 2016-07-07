module.exports = (evt)->
  return unless evt?.dataTransfer

  tids = evt.dataTransfer.getData("text/track-ids").split(",")
  rids = evt.dataTransfer.getData("text/release-ids").split(",")
  tracks = tids.map (id)-> {id: id}
  releases = rids.map (id)-> {id: id}

  tracks: tracks
  releases: releases
