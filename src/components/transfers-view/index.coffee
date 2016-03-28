View = require("view-plugin")
find = require("find-target-node")

createPackage = (transfer)->
  type = transfer.format.type.toUpperCase()
  type += " " + transfer.format.bitrate if transfer.format.bitrate

  id: transfer.id
  name: transfer.name or transfer.id
  details: "Archive of #{transfer.count} #{type} Tracks."
  status: transfer.status
  url: transfer.url
  filename: "#{transfer.name or transfer.id}.zip"

createUpload = (transfer)->
  id: transfer.id
  name: transfer.filename
  details: "#{transfer.trackname}"
  status: transfer.status
  progress: (transfer.progress * 100).toFixed()

translate = (transfers)->
  Object.keys(transfers.cache).map (key)->
    transfer = transfers.get(key)
    switch transfer.type
      when "package" then return createPackage(transfer)
      when "upload" then return createUpload(transfer)
    transfer

onAnchorClick = (e)->
  parent = find e.target, (target)->
    target.getAttribute && !!target.getAttribute("transfer-id")
  return if !parent

  # Delay the call so we don't render right away and allow events to bubble.
  setTimeout =>
    transfer = @transfers.get(parent.getAttribute("transfer-id"))
    transfer.set("status", "Downloaded")
  , 100

TransfersView = v = bQuery.view()

v.use View
  className: "downloads-view"
  template: require("./template")

v.init (opts={})->
  { @transfers } = opts
  @transfers.on("change", @render.bind(@))

v.set "render", ->
  @renderer.locals.transfers = translate(@transfers)
  @renderer.render()
  @n.bindAll("a", "click", onAnchorClick.bind(@))

module.exports = v.make()
