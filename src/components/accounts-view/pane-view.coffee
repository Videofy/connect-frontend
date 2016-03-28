view                       = require 'view-plugin'
search                     = require 'search-plugin'
AccountUsersView           = require './account-users-view'
TabView                    = require('tab-view')
AccountView                = require('./account-view')
UserWebsiteDetailsView     = require('user-website-details-view')
WebsiteDetailsModel        = require("website-details-model")

PaneView = v = bQuery.view()

v.use view
  tagName: 'tr'
  className: 'pane account-pane'
  template: require('./pane-template')
  binder: 'property'
  locals: ->
    roles: @i18.strings.roles
    name: @model.get 'name'

v.use search
  target: '[role="search-users"]'
  empty: 'No Users Found.'
  prompt: 'Search for User.'
  select: (value)->
    @selectedUser = @users.get(value)
  getItems: (filter, done)->
    @users.toPromise().then =>
      # Set no results if empty filter
      if not filter
        done([])
      else
        sorted = search.searchCollection(@users, ['name', 'email'], filter).map (model)->
          text: model.getNameAndRealName()
          value: model.id
        sorted.sort (a, b)->
          a.text.localeCompare(b.text)
        done(sorted)

v.init (opts={})->
  { @model, @users } = opts

  throw Error('Model must be provided.') unless @model
  throw Error('Users must be provided.') unless @users

  wopts = _.extend(_.clone(opts),
    model: new WebsiteDetailsModel
      _id: @model.get('websiteDetailsId')
    user: @model
  )

  @tabs = new TabView
  @tabs.set
    account:
      title: 'Account'
      view: new AccountView(opts)
    website:
      title: 'Website'
      view: new UserWebsiteDetailsView(wopts)

  @tabs.active = 'account'

v.set 'render', ->
  @renderer.render()
  @tabs.render()
  @n.getEl('td').appendChild(@tabs.el)

v.set 'open', ->
  return unless not @opened
  @opened = true

module.exports = v.make()
