DetailsView   = require('release-details-view')
PackagesView  = require('release-packages-view')
StatusView    = require('status-view')
TabView       = require('tab-view')
view          = require('view-plugin')

ReleasePageView = v = bQuery.view()

v.use view
  className: 'release-page-view'

v.init (opts={})->
  @tabs = new TabView
  @tabs.set
    details:
      title: "Information"
      view: new DetailsView(opts)
    packages:
      title: "Packages"
      view: new PackagesView(opts)
  @tabs.active = 'details'

  statusOpts = _.clone(opts)
  statusOpts.getErrors = @model.getErrors.bind(@model)
  @status = new StatusView(statusOpts)

v.set 'render', ->
  @tabs.render()
  @model.toPromise().then =>
    @status.render()
  @el.appendChild(@tabs.el)
  @el.insertBefore(@status.el, @el.firstChild)

module.exports = v.make()
