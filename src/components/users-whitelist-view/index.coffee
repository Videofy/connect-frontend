downloadString              = require("download-string")
PaneUtil                    = require("pane-util")
PaneView                    = require("pane-view")
request                     = require("superagent")
sortutil                    = require("sort-util")
UserWhitelistRowView        = require("user-whitelist-row-view")
view                        = require('view-plugin')
WhiteListBodyView           = require("user-whitelist-body-view")
fsr                         = require('collection-fsr-plugin')
fsrRenderRows               = require('fsr-render-rows')
cancel                      = require('input-cancel-plugin')
UserCollection              = require('user-collection')

sortPaid = (a, b)->
  ar = a.requiresSubscription()
  br = b.requiresSubscription()
  sort = 0
  if ar and not br
    sort = -1
  if br and not ar
    sort = 1
  sort

getWhitelistItemsByName = (model, name)->
  items = model.get("whitelist").filter (item)->
    item.name.toLowerCase() is name and item.active is true and item.whitelisted isnt true
  items.map (item)-> item.identity

onChangeActivesOnly = (e)->
  @activesOnly = @el.querySelector("[role='actives-only']").checked
  @renderRows()

onClickMarkWhitelisted = (e)->
  return unless confirm(@i18.strings.whitelist.markWhitelistConfirm) and resultModels = getResultModels.call(@)

  models = resultModels.filter ( model ) ->
    !model.requiresSubscription()
  ids = models.map ( model ) -> model.id
  status = "whitelisted"

  request
  .post("/user/batch-whitelisted")
  .send
    ids: ids
  .end ( err, res ) =>
    return alert(err) if err?
    if res.status isnt 200
      return alert(res.body?.error or res.body?.message or "An error occured.")
    resultModels.forEach ( model ) ->
      model.set("whitelistStatus", 'whitelisted')
      model.fetch({ success: (res)=>
        model.updateWhitelist()
      })

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
  "change [role='actives-only']": onChangeActivesOnly
  "click [role='mark-whitelisted']": onClickMarkWhitelisted
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
  interceptFilterValue: (el, prop, value)->
    return undefined if value is ''
    value

  renderRows: fsrRenderRows
    createRow: (model, pane)->
      new UserWhitelistRowView
        model: model
        i18: @i18
        evs: @evs
        permissions: @permissions
        pane: pane
    createPane: (model)->
      new PaneView
        colspan: 7
        body: new WhiteListBodyView
          model: model
          i18: @i18
          evs: @evs
          permissions: @permissions

  selectFilter:
    type: (type)-> (userTypes, model)->
      return true if not type

      isLicensee = model.isOfTypes('licensee')
      isSubscriber = model.isOfTypes('subscriber')

      if type is 'sponsored'
        return true if isLicensee and not isSubscriber

      if type is 'licensee'
        return true if isLicensee and isSubscriber

      false

    whitelist: (type)-> (whitelist, model)->
      result = false
      whitelist.forEach (item)->
        if item.active is true and item.whitelisted isnt true and type is 'adding'
          result = true
        else if item.active isnt true and item.whitelisted is true and type is 'removing'
          result = true

      result

v.set 'setFilter', (needle)->
  propFilter = fsr.createPropertyFilter(@filters)
  filter = fsr.createFilter(needle, [
    'email'
    'name'
    'created'
  ])

  @filter = (model)=>
    return false if not propFilter(model)
    return false if @activesOnly and model.requiresSubscription()
    if needle then filter(model) else true

v.set 'setSort', (field, mode)->
  sort =
    type: 'stringsInsensitive'
    field: field or 'created'
    mode: mode or 'asc'
  sort.type = 'dateStrings' if field is 'created'
  sort.field = sortPaid if field is 'paid'
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
