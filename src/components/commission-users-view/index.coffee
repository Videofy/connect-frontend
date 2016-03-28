Chart = require("ratio-chart")
parse = require('parse')
Ratio = require("ratio")
rows  = require("./rows-template")
sort  = require("sort-util")
view  = require("view-plugin")
search = require("search-plugin")
fractionize = require('fraction-buttons-plugin')
dt = require('date-time')

fdate = (str)->
  dt.format('Y-m-d', new Date(str))

getRatios = (model, users)->
  splits = model.get('splits')

  r = Ratio(model.get('labelRatio'))
  arr = [
    value: r
    label: "Label"
  ]
  remainder = Ratio(1).minus(r)
  splits.forEach (split)->
    arr.push
      value: Ratio(split.ratio).times(remainder)
      label: users.get(split.userId).get('name')
  arr

updateDisplay = (el, user, ratio)->
  @toast("Commission for #{user.getNameAndRealName()} was updated.",
        "success")
  @updateChart()
  el.querySelector("[role='percentage']")
    .textContent = (ratio.valueOf() * 100).toFixed(2) + "%"

onChangeCommission = (e)->
  el = e.currentTarget
  userId = el.getAttribute("user-id")
  user = @users.get(userId)
  ratio = Ratio(el.value)

  @model.changeSplit ratio, userId, (err, model)=>
    return @toast(err.message, 'error') if err
    updateDisplay.call(@, el.parentElement.parentElement, user, ratio)

onClickAdd = (e)->
  target = '[role="search-users"]'
  return unless id = @getSearchInputValue(target)

  publishSel = @n.getEl("[role='publisher']")
  isAccount = !!@accounts.get(id)
  publisherId = publishSel?.value

  splits = []
  if isAccount
    splits = @accounts.get(id)?.get('users')?.map (user)->
      userId: user.userId
      ratio: new Ratio(user.commissionRatio or 0)
  else
    splits = [{
      userId: id
      ratio: new Ratio(0)
    }]

  @model.addSplits splits, publisherId, (err, model, splits)=>
    return @toast(err.message, 'error') if err
    names = splits
      .map((split)=> @users.get(split.userId).get('name'))
      .join(', ')

    @toast("Successfully added users #{names} to commissions.",
        "success")

    @renderUsers()

    @n.getEl('[role="search-input"]')?.value = ''
    publishSel?.selectedIndex = 0
    @resetSearchInputValue(target)

onClickRemove = (e)->
  userid = e.currentTarget.getAttribute("user-id")
  @model.removeSplit userid, (err, model)=>
    return @toast(err.message, 'error') if err
    @toast("Successfully removed the commission.", "success")
    @removeUser(userid)

findUserOrAccount = (id)->
  @users.get(id) || @accounts.get(id)

onClickCompleteFraction = (e)->
  userId = e.target.getAttribute('target-user')
  @model.setRemainingSplit userId, (err, model)=>
    return @toast(err.message, 'error') if err
    split = model.getSplit(userId)
    ratio = split?.ratio or new Ratio(0)
    el = e.target.parentElement.parentElement.parentElement
    updateDisplay.call(@, el, @users.get(userId), ratio)
    el.querySelector("[fraction-target]").value = ratio.toString()

onChangeSplitDate = (e)->
  type = e.target.getAttribute('split-date')
  userid = e.target.getAttribute('user-id')
  value = new Date(e.target.value.replace('-', '/'))
  @model.setSplitDate userid, type, value, (err, model)=>
    return @toast(err.message, 'error') if err

CommissionUsersView = v = bQuery.view()

v.use view
  className: "commission-users-view"
  template: require("./template")
  locals: ->
    editable: !@viewOnly
    publishers: @publishers

v.use search
  target: '[role="search-users"]'
  empty: 'No User or Account Found.'
  prompt: 'Search for User or Account.'
  getItems: (filter, done)->
    @accounts.toPromise()
    .then =>
      @userOrAccounts = @userOrAccounts || @users.models.concat(@accounts.models)
      if not filter
        done([])
      else
        results = search.searchCollection(@userOrAccounts, ['name'], filter).map (model)->
          text: model.get('name')
          value: model.id

        done(results)

v.use(fractionize())

v.ons
  "click [role='add-split']": onClickAdd
  "click [role='remove-split']": onClickRemove
  "change [role='user-split']": onChangeCommission
  "change [split-date]": onChangeSplitDate
  "click [role='complete-fraction']": onClickCompleteFraction

v.init (opts={})->
  { @users, @viewOnly, @publishers, @accounts } = opts
  throw Error('No users collection.') unless @users
  throw Error('No accounts collection.') unless @accounts
  @chart = new Chart
    size: 180
    chart:
      showTooltips: true
      animation: false
      tooltipTemplate: "<%if (label){%><%=label%> - <%}%><%= (value * 100).toFixed(2) %>%"
  @listenTo @model, 'change:labelRatio', @updateChart.bind(@)

v.set "render", ->
  @renderer.locals.mode = 'loading'
  @renderer.render()
  @users.toPromise()
  .then =>
    return @publishers.toPromise() if @publishers
  .then =>
    @renderer.locals.mode = 'view'
    @renderer.render()
    @n.getEl("[role='chart']").appendChild(@chart.el)
    @renderUsers()

v.set "renderUsers", ->
  return unless body = @n.getEl("tbody")
  body.innerHTML = ""
  @model.get('splits').forEach (split)=> @addUser(body, split)
  @updateChart()

v.set "updateChart", ->
  @chart.set(getRatios(@model, @users))
  @updateError()

v.set "updateError", ->
  return unless @n.getEl('[role="error"]')
  @n.evaluateClass("[role='error']", "hide", @model.isWhole())

v.set 'addUser', (body, split)->
  body.innerHTML += rows
    split: split
    editable: !@viewOnly
    publishers: @publishers
    users: @users
    formatDate: fdate

v.set "removeUser", (uid)->
  trs = Array::slice.call @el.querySelectorAll('tr[user-id="'+uid+'"]')
  trs.forEach (tr)-> tr.parentElement.removeChild(tr)

module.exports = v.make()
