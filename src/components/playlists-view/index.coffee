ContextMenu                   = require("context-menu-plugin")
DragDetector                  = require("drag-detector")
DragTracksToggle              = require("drag-tracks-toggle-plugin")
View                          = require("view-plugin")
Formats                       = require("formats")
dropperData                   = require("dropper-data")
PlaylistDownloadPartsPlugin   = require('playlist-download-parts-plugin')
PlaylistModel                 = require('playlist-model')

getIndex = (el)->
  parseInt(el.getAttribute("index"))

PlaylistsView = v = bQuery.view()

v.ons
  "click [role='add']": "onClickAdd"
  "click [role='items'] > li": "onClickItem"
  "dragenter [role='items'] > li": "onDrag"
  "dragleave [role='items'] > li": "onDrag"
  "dragover [role='items'] > li": "onDrag"
  "drop [role='items'] > li": "onDrop"

v.use View
  className: "playlists-view"
  template: require("./template")

v.use ContextMenu
  evs: ["click [role='options']", "contextmenu"]

v.use DragTracksToggle()

v.use PlaylistDownloadPartsPlugin()

v.init (opts={})->
  { @user, @player, @tracks, @releases, @user, @subscription } = opts

  @player.on "change", @onChangePlayer.bind(@)
  @collection.on "add change", => @render()

v.set "render", ->
  if @user.requiresSubscription(@subscription)
    @renderer.locals.subscribed = false
    @renderer.locals.playlists = []
    @renderer.render()
    return

  # TODO show loading...
  @collection.toPromise().then =>
    @renderer.locals.subscribed = true
    @renderer.locals.playlists = @collection.map (item)-> item.attributes
    @renderer.render()
    @registerDragging()
    @displayActive()

v.set "registerDragging", ->
  playlists = @n.getEl("[role='items']")
  for li, i in playlists.children
    continue if li.classList.contains("add-playlist")
    (new DragDetector(li, li)).listen()

v.set "displayActive", ->
  return if not @player.playlist

  playlists = @n.getEl("[role='items']")
  for li, i in playlists.children
    if li.getAttribute("playlist-id") is @player.playlist.id
      li.classList.add("active")
    else
      li.classList.remove("active")

v.set "renamePlaylist", (el)->
  return if not playlist = @collection.at(getIndex(el))

  if name = prompt(@i18.strings.playlist.newMsg,
                    playlist.get("name"))
    playlist.name = name
    playlist.save 
      name: name
    , 
      success: (model, res, opts)=>
        @render()
      error: (model, res, opts)=>
        @evs.trigger "toast",
          text: @i18.strings.playlist.errorMsg
          theme: error
          time: 2500

v.set "deletePlaylist", (el)->
  return if not playlist = @collection.at(getIndex(el))

  if confirm("Are you sure you want to delete this playlist?")
    playlist.destroy()
    @render()

v.set "onClickItem", (e)->
  return if not playlist = @collection.at(getIndex(e.target))
  @evs.trigger("changeplaylist", playlist)
  @evs.trigger("openplaylist")

v.set "onClickAdd", (e)->
  if name = prompt("Please enter a name for the new playlist.", 
    "New Playlist")
    @collection.create 
      name: name
      tracks: []
    , 
      error: (model, xhr, opts)=>
        alert("There was an error trying to create the playlist.")

v.set "onChangePlayer", ->
  @displayActive()

v.set "onDrag", (e)->
  e.preventDefault()

v.set "onDrop", (e)->
  e = e.originalEvent
  e.preventDefault()

  id = e.target.getAttribute("playlist-id")
  return if not playlist = @collection.get(id)

  { tracks, releases } = dropperData(e)
  return if not tracks.length or tracks.length isnt releases.length

  tracks.forEach (track, index, arr)-> 
    playlist.addTrack(track, releases[index])

  playlist.save()

v.set "onOpenContextMenu", (source)->
  target = source
  el = undefined
  items = []

  while target and not el
    el = target if target.getAttribute("playlist-id")
    target = target.parentElement

  if el
    playlist = @collection.get(el.getAttribute('playlist-id'))
    items.push
      el: el
      action: "rename"
      name: "Rename"
    items.push
      el: el
      action: "delete"
      name: "Delete"
    if not playlist.get('public')
      items.push
        el: el
        action: "public"
        name: "Make Public"
    else
      items.push
        el: el
        action: 'private'
        name: "Make Private"
    items.push
      el: el
      action: 'id'
      name: "Get Id"

    parts = playlist.getDownloadParts(playlist.get('tracks').length)

    if parts > 1
      for format, i in Formats.defaults
        items.push
          name: format.name
          action: "openDownloadParts"
          format: format
          playlist: playlist
    else
      for format, i in Formats.defaults
        items.push
          action: "download"
          name: format.name
          separated: if i is 0 then true else false
          format: format
          anchor:
            download: true
            url: playlist.downloadUrl(format.type, format.quality)
            target: "_blank"

  @contextMenu.setItems(items)

v.set "onSelectContextMenu", (item)->
  id = item.el?.getAttribute('playlist-id')
  action = item.action
  @renamePlaylist(item.el) if action is "rename"
  @openDownloadParts(item.format.type, item.format.quality, item.playlist) if action is "openDownloadParts"
  @deletePlaylist(item.el) if action is "delete"
  @makePublic(id, yes) if action is 'public'
  @makePublic(id, no) if action is 'private'
  window.alert('Playlist ID: ' + id) if action is 'id'


v.set "makePublic", (id, value)->
  return unless playlist = @collection.get(id)
  playlist.save public: !!value,
    error: (model, res, opts)=>
      err = parse.backbone.error(res)
      @toast(err.message, 'error')
    success: (model, res, opts)=>
      type = if value then 'public' else 'private'
      @toast('Playlist "' + playlist.get('name') + '" is now ' + type + '.', 'success')

module.exports = v.make()
