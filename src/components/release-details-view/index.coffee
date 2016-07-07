FileDropper          = require('file-dropper')
InputListView        = require('input-list-view')
parse                = require('parse')
TracksView           = require('release-tracks-view')
upload               = require('file-uploader')
view                 = require('view-plugin')
wait                 = require('wait')
dt                   = require('date-time')
disabler             = require('disabler-plugin')
validation           = require('validation-plugin')

iv = bQuery.view()

iv.use view
  className: "ss"
  tagName: "input"

iv.init (opts={})->
  @el.type = opts.type or 'text'

InputView = iv.make()

onValidated = (valid, files)->
  return if !valid or !files or !files.length

  el = @n.getEl('[role="upload-cover-art"]')
  el.classList.add('active')
  filename = files[0].name
  upload.files
    url: "#{@model.url()}/cover"
    files: files
    method: 'put'
  , wait 750, @, (err, req)=>
    el.classList.remove('active')

    if err = parse.superagent(err, req)
      return @toast err.message, 'error'

    @toast "#{@model.get('title')} cover art updated succesfully.", 'success'
    @model.fetch
      success: =>
        @n.evaluateDisabled('[role="view-art"]', !@model.hasArt())

onViewArt = ->
  window.open(@model.coverUrl(null, @label.get('name')), "_blank")

ReleaseDetailsView = v = bQuery.view()

v.use view
  className: 'release-details-view'
  template: require("./template")
  binder: 'property'
  locals: ->
    types: Object.keys(@i18.strings.releaseTypes)
    features: @label.features ? { website: {} }
    permissions: @permissions.release
    art:
      link: @model.coverUrl(null, @label.get('name'))
      src: @model.coverUrl(128, @label.get('name'))
    format: dt.format

v.use validation()

v.use disabler
  attribute: 'editable'

v.init (opts={})->
  { @label, @tracks, @player } = opts

  throw Error("Model is required.") unless @model
  throw Error("Label is required.") unless @label
  throw Error("Tracks collection is required.") unless @tracks

  @altnames = new InputListView
    model: @model
    placeholder: ''
    property: 'altNames'
    type: 'text'

  @urlsView = new InputListView
    model: @model
    property: "urls"
    placeholder: "URL"
    type: 'text'

v.ons
  'click [role="view-art"]': onViewArt

v.set "render", ->
  @stopListening(@model)
  @renderer.locals.mode = 'loading'
  @renderer.render()

  @model.sfetch (err, model)=>
    if err
      @renderer.locals.mode = 'error'
      @renderer.locals.error = err.message
      @renderer.render()
      return

    @renderer.locals.mode = 'view'
    @renderer.render()

    @tracksview = new TracksView
      evs: @evs
      i18: @i18
      model: @model
      permissions: @permissions
      player: @player
      tracks: @tracks
    @tracksview.render()
    @n.getEl('[role="tracks"]').appendChild(@tracksview.el)

    @dropper = new FileDropper
      el: @n.getEl('[role="upload-cover-art"]')
      types: ["application/jpeg", "application/png"]
    @dropper.on("validated", onValidated.bind(@))

    @altnames.render()
    @n.getEl('[role="altnames"]').appendChild(@altnames.el)

    @urlsView.render()
    @n.getEl('[role="links"]').appendChild(@urlsView.el)

    @renderPlaylist()
    @listenTo(@model, 'change:type', @renderPlaylist.bind(@))

v.set 'renderPlaylist', ->
  type = @model.get('type')
  @n.evaluateClass('[role="playlist"]', 'hide', type not in ['Mixes', 'Podcast'])

module.exports = v.make()
