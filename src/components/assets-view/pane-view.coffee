CommissionCollection    = require('commission-b-collection')
CommissionsView         = require('commissions-b-view')
DetailsView             = require('./details-view')
TabView                 = require('tab-view')
view                    = require('view-plugin')

v = bQuery.view()

v.use view
  tagName: 'tr'
  className: 'pane pane-tabbed'
  template: require('./pane-template')

v.init (opts={})->
  { @users, @accounts } = opts

  throw Error('Users collection must be provided.') unless @users

  commissions = new CommissionCollection null,
    by:
      key: 'assetId'
      value: @model.id

  @commissionsView = new CommissionsView
    collection: commissions
    evs: @evs
    i18: @i18
    permissions: @permissions
    users: @users
    accounts: @accounts
    types:
      merchandise: 'Merchandise'

  @tabs = new TabView
  @tabs.set
    info:
      title: 'Information'
      view: new DetailsView(opts)
    commissions:
      title: 'Commissions'
      view: @commissionsView

  @tabs.active = 'info'

v.set 'render', ->
  @renderer.render()
  @tabs.render()
  @el.firstChild.appendChild(@tabs.el)

module.exports = v.make()
