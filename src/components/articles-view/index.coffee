Article = require('article-model')
rows    = require('./rows-template')
Dropper = require('file-dropper')
fsr     = require('collection-fsr-plugin')
parse   = require('parse')
view    = require("view-plugin")

onValidated = (valid, files)->
  titleEl = @n.getEl('[role="new-article-title"]')
  title = titleEl.value

  return unless valid and title

  attr =
    title: title
  attr[@collection.by.key] = [@collection.by.value]
  model = new Article()
  model.save attr,
    error: (model, res, opts)=>
      @toast(parse.backbone.error(res), 'error')
    success: (model, res, opts)=>
      model.upload files[0], (err)=>
        if err
          @toast(err.message, 'error')
          return model.destroy()
        @collection.add(model)
        @toast('Article successfully created.', 'success')
        titleEl.value = ''

onClickDestroy = (e)->
  id = e.currentTarget.getAttribute('article-id')
  model = @collection.get(id)

  return unless window.confirm("Are you sure you want to delete this article?")

  model.destroy
    error: (model, res, opts)=>
      @toast(parse.backbone.error(err).message, 'error')
    success: (model, res, opts)=>
      @toast('The article "'+model.get('title')+'" successfully destroyed.', 'success')

ArticlesView = v = bQuery.view()

v.use view
  className: "articles-view"
  template: require("./template")

v.use fsr
  rowsTemplate: require('./rows-template')

v.ons
  'click [role="destroy-article"]': onClickDestroy

v.set 'setSort', ->
  @sort =
    type: 'stringsInsensitive'
    field: 'title'
    mode: 'desc'

v.set 'setFilter', ->
  @filter = ''

v.set 'setRange', ->
  @range =
    start: 0
    increment: @collection.length

v.set "render", ->
  @renderer.render()
  @dropper = new Dropper
    el: @n.getEl('[role="upload-article"]')
    types: 'application/pdf'
  @dropper.on('validated', onValidated.bind(@))
  @renderRows()

module.exports = v.make()
