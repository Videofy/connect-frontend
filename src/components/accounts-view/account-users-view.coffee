view                 = require 'view-plugin'
rows                 = require './users-rows-template'

onDeleteUser = (e)->
  id = e.currentTarget.getAttribute 'user-id'
  users = @model.get 'users'
  usersToDel = users.filter (user)->
    return user.userId is id

  return unless users.length
  return unless confirm('Are you sure you want to delete this user from the account?')

  users.splice(users.indexOf(usersToDel[0]), 1)
  @model.save
    users: users
  ,
    wait: true
    patch: true
    error: (model, res, opts)=>
      @toast(parse.backbone.error(res), 'error')
    success: (model, res, opts)=>
      @toast("User \"#{@users.get(id).get('name')}\" was successfully removed from the account.", 'success')
      @renderRows()

AccountUsersView = v = bQuery.view()

v.use view
  className: 'account-users-view'
  template: require('./account-users-template')
  locals: ->
    roles: @i18.strings.roles

v.init (opts={})->
  { @model, @users } = opts

  throw Error('Model must be provided.') unless @model
  throw Error('Users must be provided.') unless @users

v.ons
  'click [role="delete"]': onDeleteUser

v.set 'render', ->
  @renderer.locals.mode = 'loading'
  @renderer.render()
  @users.toPromise()
  .then =>
    @renderer.locals.mode = 'view'
    @renderer.render()
    @renderRows()

v.set 'renderRows', ->
  return unless accountEl = @n.getEl('[role="account-users"]')

  accountUsers = @model.get('users').map (user)=>
    userId: user.userId
    email: user.email
    commissionRatio: user.commissionRatio
    role: @i18.strings.roles[user.role]
    name: @users.get(user.userId).get('name')

   accountEl.innerHTML = rows
    users: accountUsers

v.set 'open', ->
  return unless not @opened
  @opened = true
  @renderRows()

module.exports = v.make()
