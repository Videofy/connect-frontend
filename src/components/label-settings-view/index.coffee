ElementModelBinder         = require("element-model-binder")
GenreEditorView            = require("genre-editor-view")
ListManageView             = require("list-manage-view")
parse                      = require('parse')
Ratio                      = require('ratio')
request                    = require("superagent")
view                       = require("view-plugin")

addLabelAdmin = ->
  request
    .post("/label/#{@model.id}/create-admin")
    .withCredentials()
    .send
      email: @n.getValue("[role='label-admin-email']")
      password: @n.getValue("[role='label-admin-password']")
    .end (err, res)=>
      if err or res.status != 201
        text = if err then "An error occured while making the request."
        else JSON.parse(res.text).message
        @evs.trigger "toast",
          time: 2500
          text: text
          theme: "error"
      else
        @evs.trigger "toast",
          time: 2500
          text: "The label admin has been created."
          theme: "success"

onChangeLabelCommission = (e)->
  el = e.currentTarget
  type = el.getAttribute('commission-type')
  r = new Ratio(el.value)
  commissions = @model.get('commissions')
  commissions[type] =
    ratio: r.toString()
    value: r.valueOf()
  @model.save commissions: commissions,
    patch: true,
    error: (model, res, opts)=>
      @toast(parse.backbone.error(res).message, 'error')

LabelSettingsView = v = bQuery.view()

v.use view
  className: "label-details-view"
  template: require("./template")

v.ons
  "click [role='add-label-admin']": addLabelAdmin
  "change [role='label-commission']": onChangeLabelCommission

v.init (opts={})->
  { @dataSources } = opts

  @isrcBinder = new ElementModelBinder
    get: ( prop ) =>
      isrc = @model.get("isrc")
      isrc[prop]
    set: ( prop, value ) =>
      isrc = @model.get("isrc")
      isrc[prop] = value
      @model.set("isrc", isrc)
      @model.trigger("change")
    save: =>
      @model.update()

  if !@model.get("genres")
    @model.set("genres", [])

  @genres = (@model.get("genres") or []).concat()
  @genresList = new ListManageView
    items: @genres
    createView: (item)=>
      new GenreEditorView
        genre: item
    createItem: =>
      name: ""
      color: "FFFFFF"
  @genresList.on "viewadd", @onGenresAdd.bind(@)
  @genresList.on "viewremove", @onGenresRemove.bind(@)

v.set "render", ->
  @renderer.render()
  @genresList.render()
  @el.querySelector("[role='genres']").appendChild(@genresList.el)

  @isrcBinder.reset()
  @isrcBinder.bindBatch [
    el: @el.querySelector("input.isrc-country")
    property: "country"
  ,
    el: @el.querySelector("input.isrc-registrant")
    property: "registrant"
  ]

v.set "updateGenres", ->
  @model.save "genres", @genres,
    patch: true
    wait: true
    error: (model, res, opts)=>
      @toast JSON.parse(res.responseText).message, 'error'

v.set "onGenresAdd", ( view, item ) ->
  view.on("change", @onGenreViewChange.bind(@))
  @updateGenres()

v.set "onGenresRemove", ( view, item ) ->
  view.off("change")
  @updateGenres()

v.set "onGenreViewChange", ( view ) ->
  @updateGenres()

module.exports = v.make()
