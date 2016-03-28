view                 = require 'view-plugin'
search               = require 'search-plugin'
AccountUsersView     = require './account-users-view'
TabView              = require('tab-view')

canAddUser = (users, newUserId)->
  c = users.filter (user)->
    user.userId == newUserId
  c.length == 0

onClickAddUser = (e)->
  roleSelect = @n.getEl('[role="new-role"]')
  option = roleSelect.options[roleSelect.selectedIndex]

  fields =
    role: if option.disabled then null else option.value
    commission: @n.getEl('[role="new-commission"]')?.value
    user: @selectedUser?.get('_id')

  missingFields = []
  for k, v of fields
    unless v
      missingFields.push(k)

  if missingFields.length
    message = "You are missing the following fields: #{missingFields.join(', ')}."
    return @toast(message, 'error')

  accountUsers = @model.get 'users'
  return @toast('User is already in account.', 'error') unless canAddUser(accountUsers, fields.user)

  @reset()
  accountUsers.push
    userId: fields.user
    commissionRatio: fields.commission
    role: fields.role

  @model.save
    users: accountUsers
  ,
    wait: true
    patch: true
    error: (model, res, opts)=>
      @toast(parse.backbone.error(res), 'error')
    success: (model, res, opts)=>
      @toast("The account's users were updated", 'success')
      @auv.render()

PaneView = v = bQuery.view()

v.use view
  # tagName: 'tr'
  tagName: 'table'
  className: 'account-view ss fsrv'
  template: require('./account-template')
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

  @auv = new AccountUsersView
    model: @model
    users: @users
    i18: @i18
    evs: @evs
    permissions: @permissions

v.set 'reset', ->
  @n.getEl('[role="new-user"]')?.value = ''
  @n.getEl('[role="new-role"]')?.selectedIndex = 0
  @n.getEl('[role="new-commission"]')?.value = ''
  @n.getEl('[role="search-users"] input')?.value = ''

  @selectedUser = null

v.set 'render', ->
  @renderer.render()
  @auv.render()
  @n.getEl('[role="container"]').appendChild(@auv.el)

v.ons
  'click [role="add-user"]': onClickAddUser

v.set 'open', ->
  return unless not @opened
  @opened = true
  @auv.render()

module.exports = v.make()
