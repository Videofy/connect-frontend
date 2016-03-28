make     = require('./create-selector')
objtodom = require('obj-to-dom')
selector = require('./selector-plugin')
view     = require('view-plugin')

sigToItem = (users, sig)->
  user = users.get(sig.connectId)
  id: user.id
  title: user.getNameAndRealName()

userToItem = (user)->
  value: user.id
  text: user.getNameAndRealName()

v = bQuery.view()

v.use view
  className: 'signatures'
  template: require('./signatures-template')

v.use selector
  resetToFirst: true
  addItem: (key, id)->
    return unless user = @users.get(id)

    if @model.addSignatureByUser(user, key) < 0
      @toast(
        'This user is not valid for signing due to missing information.',
        'error')
      return undefined

    id: user.id
    title: user.getNameAndRealName()
  removeItem: (key, id)->
    return undefined unless user = @users.get(id)
    index = @model.removeSignatureByUser(user, key)
    return undefined unless index > -1
    index

v.init (opts={})->
  { @user, @users } = opts

  throw Error('Model must be provided.') unless @model
  throw Error('User model must be provided.') unless @user
  throw Error('Users collection must be provided.') unless @users

v.set 'render', ->
  @renderer.render()
  @users.toPromise().then =>
    first =
      disabled: true
      text: 'Select One'
      value: ''
      first: true
    sopts = @users.getContractable().map(userToItem)
    vopts = @users.getContractViewable().map(userToItem)
    sopts.unshift(first)
    vopts.unshift(first)
    method = sigToItem.bind(null, @users)
    sigs = @model.get('signatures').map(method)
    viws = @model.get('viewers').map(method)
    signeesSelect = objtodom(make.select('signatures', sopts, sigs))
    viewersSelect = objtodom(make.select('viewers', vopts, viws))
    o = @n.getEl('[role="signatures"]')
    o.removeChild(o.firstChild)
    o.appendChild(signeesSelect.el)
    o = @n.getEl('[role="viewers"]')
    o.removeChild(o.firstChild)
    o.appendChild(viewersSelect.el) #lazy

module.exports = v.make()
