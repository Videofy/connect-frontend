downloadString              = require("download-string")
PaneUtil                    = require("pane-util")
PaneView                    = require("pane-view")
sortutil                    = require("sort-util")
UserWhitelistRowView        = require("user-whitelist-row-view")
view                        = require('view-plugin')
fsr                         = require('collection-fsr-plugin')
fsrRenderRows               = require('fsr-render-rows')
cancel                      = require('input-cancel-plugin')
UserCollection              = require('user-collection')
UserPageView                = require('user-page-view')
SubscriptionModel           = require('subscription-model')

getWhitelistItemsByName = (model, name)->
  items = model.get("whitelist").filter (item)->
    item.name.toLowerCase() is name and item.active is true and item.whitelisted isnt true
  items.map (item)-> item.identity

onClickDownloadYouTube = (e)->
  @download "licensee-youtube-channels.txt", ( model ) =>
    getWhitelistItemsByName(model, "youtube")

onClickDownloadTwitch = (e)->
  @download "licensee-twitch-names.txt", ( model ) =>
    getWhitelistItemsByName(model, "twitch")

onClickDownloadEmails = (e)->
  @download "emails.csv", (model)=>
    name = model.get('realName') or ''
    (model.get('email') or '').split(',')
      .map (email)->
        "#{name}, #{email}"
      .join("\n")

onClickDownload = (e)->
  selectEl = @el.querySelector("[role='download-picker']")
  switch selectEl.options[selectEl.selectedIndex].value
    when "download-youtubes" then onClickDownloadYouTube.call(@, e)
    when "download-twitchs" then onClickDownloadTwitch.call(@, e)
    when "download-emails" then onClickDownloadEmails.call(@, e)

getResultModels = ->
  opts =
    sort: @sort
    filter: @filter
    range: @range
  @collection.getPage(opts)

UsersWhitelistView = v = bQuery.view()

v.use view
  className: 'users-whitelist-view ss table-fsrv'
  template: require('./template')

v.use cancel
  target: '[role="filter"]'
  button: '[role="cancel-filter"]'

v.ons
  "click [role='download']": onClickDownload

v.init (opts={})->
  @collection = new UserCollection null,
    by:
      key: 'type'
      value: 'licensee'
    fields: [
      'realName',
      'email',
      'created',
      'whitelist',
      'subscriber',
      'type',
      'whitelistStatus',
      'subscriptionModelId']

v.set 'open', (needle)->
  @setFilter(needle)
  @render()

v.set "render", ->
  return if @renderer.locals.mode is 'loading'
  @renderer.locals.mode = 'loading'
  @renderer.render()
  @collection.sfetch (err)=>
    if err
      @renderer.locals.mode = 'error'
      @renderer.locals.error = err.message
      @renderer.render()
      return
    @renderer.locals.mode = 'view'
    @renderer.render()
    @updateFilters()
    @renderRows()

v.use fsr
  renderRows: fsrRenderRows
    createRow: (model, pane)->
      new UserWhitelistRowView
        model: model
        i18: @i18
        evs: @evs
        permissions: @permissions
        pane: pane
        subscription: pane?.body?.subscription

    createPane: (model)->
      subscription = new SubscriptionModel
        _id: model.get('subscriptionModelId')

      new PaneView
        colspan: 5
        body: new UserPageView
          evs: @evs
          i18: @i18
          model: model
          permissions: @permissions
          subscription: subscription

v.set 'setFilter', (needle)->
  filter = fsr.createFilter(needle, [
    'email'
    'name'
    'created'
  ])
  @filter = (model)=>
    whitelist = model.get('whitelist') or []
    for el, i in whitelist
      if el.identity is needle
        return true
    filter(model)

v.set 'setSort', (field, mode)->
  sort =
    type: 'stringsInsensitive'
    field: field or 'created'
    mode: mode or 'asc'
  sort.type = 'dateStrings' if field is 'created'
  @sort = sort

v.set 'setRange', (start=0, increment=100)->
  @range =
    start: start
    increment: increment

# Downloads a text file that has all of the values of the property.
v.set "download", (filename, predicate, separator="\n")->
  return unless resultModels = getResultModels.call(@)

  arr = []
  resultModels.forEach (model)-> arr = arr.concat(predicate(model))
  arr = arr.filter (value)-> !!value.length
  buffer = arr.join(separator)
  downloadString(filename, buffer)

module.exports = v.make()
