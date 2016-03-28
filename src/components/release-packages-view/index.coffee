formats         = require('formats')
humanize        = require('humanize-string')
mkCrudColl      = require('crud-collection')
parse           = require('parse')
request         = require('superagent')
rows            = require('./rows-template')
sort            = require('sort-util')
view            = require('view-plugin')
wait            = require('wait')

releaseEvs = ['failed', 'packaged', 'progress', 'new', 'upload-failed', 'uploaded', 'finished']
releaseEvsPrefix = 'release-package-'

PackageCollection = mkCrudColl baseUri: 'package'

onClickCreatePackage = (e)->
  el = e.currentTarget
  el.classList.add('active')
  el.disabled = true
  @model.package wait 750, @, (err, res)=>
    @toast(err.message, 'error') if err
    el.classList.remove('active')
    el.disabled = false

onPackageUpdate = (status, e)->
  try
    data = JSON.parse(e.data)
  catch e
    return
  return unless @model.id is data.releaseId
  refresh.call(@, @n.getEl('[role="refresh"]'))

onClickRefresh = (e)->
  refresh.call(@, e.currentTarget)

refresh = (el)->
  el?.disabled = true
  el?.classList.add("active")
  @collection.toPromise(true).then wait 1000, @, =>
    @renderRows()
    el?.disabled = false
    el?.classList.remove("active")

formatstr = (str)->
  str.split('-').map((str)-> humanize(str)).join(' ')

initCollection = ->
  @collection = new PackageCollection null,
    by:
      key: 'releaseId'
      value: @model.id
  @listenTo(@collection, 'change', @renderRows.bind(@))

  releaseEvs.forEach (ev)=>
    @sse.addEventListener(releaseEvsPrefix + ev, onPackageUpdate.bind(@, ev))

ReleasePackagesView = v = bQuery.view()

v.ons
  'click [role="create-package"]': onClickCreatePackage
  'click [role="refresh"]': onClickRefresh

v.use view
  className: 'release-packages-view'
  template: require('./template')

v.init (opts={})->
  throw Error('A release model must be provided.') unless @model
  if @model.id
    initCollection.call(@)
  else
    @model.once('change:_id', initCollection.bind(@))

v.set 'render', ->
  @renderer.locals.mode = if not @model.id then 'fresh' else 'loading'
  @renderer.render()

  if not @model.id
    return @model.once('change:_id', @render.bind(@))

  @collection.toPromise().then =>
    @renderer.locals.mode = 'ready'
    @renderer.locals.collection = @collection
    @renderer.render()
    @renderRows()

v.set 'renderRows', ->
  ms = @collection.models.slice()
  ms.sort(sort.object('dateStrings', 'attributes.createdDate', -1))
  @n.getEl('tbody')?.innerHTML = rows
    models: ms
    humanize: formatstr
    strings: @i18.strings

module.exports = v.make()
