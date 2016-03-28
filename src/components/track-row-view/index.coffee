ContextMenu   = require("context-menu-plugin")
FileDropper   = require("file-dropper")
Formats       = require("formats")
player        = require("private-player-plugin")
StringUtil    = require("string-util")
TrackModel    = require("track-model")
View          = require("view-plugin")
upload        = require("file-uploader")
rowView       = require("row-view-plugin")

onDropperValidated = (valid, files)->
  return if !valid or !files or !files.length

  filename = files[0].name

  transfer = @transfers.create()
  transfer.req = upload.files
    url: "#{@model.url()}/wav"
    files: files
    method: 'put'
  , (err, req)=>
    transfer.set("status", if err then "Failed" else "Finished")

    if err
      stat = "#{filename} has failed to upload."
      theme = "error"
    else
      stat = "#{filename} has finished uploading."
      theme = "success"
      @model.fetch()

    transfer.set("seen", false)
    @toast(stat, theme)
    @uploading(false)

  transfer.req.on "progress", (e)->
    transfer.set("progress", e.loaded / e.total)
  transfer.type = "upload"
  transfer.filename = filename
  transfer.progress = 0
  transfer.trackname = @model.get("title") or ""
  transfer.set("status", "Uploading")

  @evs.trigger "toast",
    time: 2500
    html: "<p>#{filename} is being uploaded. To view your active transfers click on the <i class='fa fa-cloud'></i> at the top of your screen.</p>"

  @uploading(true)

onClickDelete = (e)->
  e.stopPropagation()
  title = @model.get("title")
  text = @i18.strings.defaults
    .destroyMsg.replace(/\{.+\}/, title)
  if confirm(text)
    @model.destroy
      wait: true
      error: (model, res)=>
        @toast(JSON.parse(res.responseText).message, "error")
      success: (model, res)=>
        @toast("The track \"#{title}\" was succesfully deleted.", "success")

onClickLink = (e)->
  e.stopPropagation()

TrackRowView = v = bQuery.view()

v.ons
  "click [role='delete']": onClickDelete
  "click [role='link']": onClickLink
  "click [role='download']": onClickLink

v.use View
  className: "pane-row track-row"
  tagName: "tr"
  template: require("./template")

v.use player
  ev: 'click [role="play"]'
  getTrack: (el)-> @model

v.use rowView

v.init ( opts ) ->
  { @transfers, @label } = opts
  @cbs =
    validated: onDropperValidated.bind(@)
  @listenTo @model, "change", @updateInterface.bind(@)

v.set 'render', ->
  @renderer.render()
  @dropper = new FileDropper
    el: @n.getEl("[role='upload']")
    types: "audio/wav"
  @dropper.on("validated", @cbs.validated)
  @updateInterface()

v.set 'updateInterface', ->
  @updateActions()
  @updateGenreColoring()
  @updateText()

v.set 'updateActions', ->
  playBtn = @n.getEl("[role='play']")
  playBtn.disabled = !@model.get("fileName")
  @n.evaluateClass(playBtn, "hide", !@permissions.track.play)
  @n.evaluateDisabled("[role='download']", !@model.get("fileName"))
  @n.evaluateDisabled("[role='delete']", !@permissions.canAccess('track.destroy'))
  @n.evaluateDisabled("[role='upload']", !@permissions.track.upload)

v.set 'updateGenreColoring', ->
  el = @el.querySelector("td.genre > .bar")
  trackGenre = @model.get("genre") ? @model.get("genres")?[0] ? "Default"
  matches = @label.get("genres").filter ( genre ) ->
    genre.name == trackGenre
  genre = matches[0]
  el.style.backgroundColor = if genre then "##{genre.color}" else undefined

v.set 'updateText', ->
  @n.setText("td.track-title", @model.get("title") or "New Track")
  @n.setText("td.artists-title", @model.get("artistsTitle") or "")
  @n.setText("td.isrc", @model.get("isrc") or "")
  @n.setText("td.date", @model.getAsFormatedDate("created", "M j, Y"))
  @n.evaluateClass("[role='status-state']", "hide", !@model.get('hasErrors'))

v.set 'uploading', (value)->
  sel = "[role='upload']"
  @n.evaluateDisabled(sel, value)
  @n.evaluateClass(sel, "active", value)

module.exports = v.make()
