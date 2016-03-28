ArticlesView          = require("articles-view")
ArticleCollection     = require("article-collection")
CommissionCollection  = require('commission-b-collection')
CommissionsView       = require("commissions-b-view")
DetailsView           = require("track-details-view")
mkCrudCollection      = require('crud-collection')
PublisherCollection   = require('publisher-collection')
ReleasesView          = require("track-releases-view")
StatusView            = require("status-view")
TabView               = require("tab-view")
view                  = require("view-plugin")

TrackPageView = v = bQuery.view()

v.use view
  className: "track-page-view pane-tabbed"
  template: require("./template")

v.init (opts={})->
  { @label, @publishers, @users, @accounts, @tracks } = opts

  throw Error('Missing publishers.') unless @publishers
  throw Error('Missing users.') unless @users
  throw Error('Missing accounts.') unless @accounts
  throw Error('Missing tracks.') unless @tracks

  statusOpts = _.clone(opts)
  statusOpts.getErrors = @model.getErrors.bind(@model)
  @status = new StatusView(statusOpts)

  dobj = _.clone(opts)
  dobj.users = @users
  dobj.accounts = @accounts
  dobj.tracks = @tracks
  dobj.label = @label

  crudopts =
    by:
      key: 'trackId'
      value: @model.id
  aobj = _.clone(opts)
  aobj.collection = new ArticleCollection(null, crudopts)

  cmobj = _.clone(opts)
  cmobj.users = @users
  cmobj.accounts = @accounts
  cmobj.publishers = @publishers
  cmobj.collection = new CommissionCollection(null, crudopts)
  cmobj.types =
    download: 'Download'
    streaming: 'Streaming'
    publishing: 'Publishing'

  @tabs = new TabView
  @tabs.set
    details:
      title: "Information"
      view: new DetailsView(dobj)
    releases:
      title: "Releases"
      view: new ReleasesView(opts)
    commissions:
      title: "Commissions"
      view: new CommissionsView(cmobj)
    articles:
      title: "Articles"
      view: new ArticlesView(aobj)
  @tabs.active = "details"

v.set "render", ->
  @renderer.render()
  @status.render()
  @tabs.render()
  @el.insertBefore(@tabs.el, @el.firstChild)
  @el.insertBefore(@status.el, @el.firstChild)

module.exports = v.make()
