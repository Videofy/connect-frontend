InputListView  = require('input-list-view')
LabelView      = require('label-view')
ListManageView = require('list-manage-view')
parse          = require('parse')
request        = require('superagent')
view           = require('view-plugin')
wait           = require('wait')
sort           = require('sort-util')
populate       = require('populate-select')
eurl           = require('end-point').url
disabler       = require('disabler-plugin')
validation     = require('validation-plugin')

onClickIsrc = (e)->
  el = e.currentTarget
  el.disabled = true
  el.classList.add('active')
  input = @n.getEl('[property="isrc"]')
  @model.generateIsrc (err) =>
    el.disabled = false
    el.classList.remove('active')
    if err
      @toast err.message, 'error'
    else
      @toast "#{@model.get('title')}'s ISRC has been generated", 'success'

onClickBpm = (e)->
  el = e.currentTarget
  el.disabled = true
  el.classList.add('active')
  input = @n.getEl('[property="bpm"]')
  request
  .post(eurl("/api/track/#{@model.id}/calculate/bpm"))
  .withCredentials()
  .end wait 750, @, (err, res)=>
    el.disabled = false
    el.classList.remove('active')
    if err = parse.superagent(err, res)
      @toast err.message, 'error'
    else
      @model.set('bpm', res.body.bpm)
      @toast "#{@model.get('title')}'s BPM was calculated. Please review.",
        'success'

onClickLength = (e)->
  el = e.currentTarget
  el.disabled = true
  el.classList.add('active')
  input = @n.getEl('[property="duration"]')
  request
  .post(eurl("/api/track/#{@model.id}/calculate/duration"))
  .withCredentials()
  .end wait 750, @, (err, res)->
    el.disabled = false
    el.classList.remove('active')
    if err = parse.superagent(err, res)
      @toast err.message, 'error'
    else
      @model.set('duration', res.body.duration)
      @toast "#{@model.get('title')}'s duration was calculated. Please review.",
        'success'

onClickDictateCatalog = (e)->
  action = if e.target.checked then 'addCatalog' else 'removeCatalog'
  @model[action] e.target.value, (err, model, catalogs)=>
    if err
      e.target.checked = !e.target.checked
      @toast(err.message, 'error')

newLabelView = ->
  view = new LabelView
  view.el.classList.add('cancel-padding')
  view

TrackDetailsView = v = bQuery.view()

v.use view
  className: 'track-details-view'
  template: require('./template')
  binder: 'property'
  locals: ->
    genres: @label.get('genres').map (genre)-> genre.name

v.use disabler
  attribute: 'editable'

v.use validation()

v.ons
  'click [role="generate-isrc"]': onClickIsrc
  'click [role="calculate-bpm"]': onClickBpm
  'click [role="calculate-length"]': onClickLength
  'click [role="dictate-catalog"]': onClickDictateCatalog

v.init (opts={})->
  { @label, @users, @tracks, label, users } = opts

  throw Error('A label must be provided.') unless label
  throw Error('User collection must be provided.') unless users

  invalidTypes = ["licensee", "gold", "subscriber"]

  fn = (property)=> (view, item, items)=>
    @model.set property, items
    @model.save null,
      patch: true
      wait: true
      error: (model, res, opts)=>
        @toast(JSON.parse(res.responseText).message, 'error')

  @lists = {}
  @ulists = {}
  arr = ['altNames', 'isrcs', 'tags']
  arr.forEach (key)=>
    @lists[key] = new InputListView
      disabled: false
      model: @model
      placeholder: ''
      property: key
      type: 'text'

  arr = ['artists', 'featuring', 'remixers']
  arr.forEach (key)=>
    lview = new ListManageView
      items: => @model.get(key)
      createView: (item)->
        labelview = newLabelView()
        labelview.el
          .textContent = users.get(item.artistId)?.getNameAndRealName() or 'Unknown User'
        labelview
      createItem: (value, text)->
        user = users.get(value)
        throw Error("User doesn't exist") unless user
        name: user.get('name')
        artistId: user.id
      getOptions: ->
        users.getArtists()
        .map (model)->
          value: model.id
          text: model.getNameAndRealName().trim()
        .sort(sort.object('stringsInsensitive', 'text'))
    lview.on 'viewadd', fn(key)
    lview.on 'viewremove', fn(key)
    @ulists[key] = lview

  @lists.genres = genres = new ListManageView
    items: @model.get.bind(@model, 'genres')
    createView: (item)->
      lview = newLabelView()
      lview.el.textContent = item
      lview
    createItem: (value, text)->
      value
    getOptions: ->
      label.get('genres').map (genre)->
        value: genre.name
        text: genre.name
  genres.on 'viewadd', fn('genres')
  genres.on 'viewremove', fn('genres')

v.set 'render', ->
  @renderer.locals.mode = 'loading'
  @renderer.render()

  @model.toPromise().then =>
    @renderer.locals.mode = 'view'
    @renderer.render()
    @renderLists(@lists)

    @users.toPromise().then =>
      @renderLists(@ulists)

    @tracks.toPromise().then =>
      selected = @model.get('remixOf')
      el = @n.getEl('[property="remixOf"]')
      el.disabled = false
      while el.firstChild
        el.removeChild(el.firstChild)
      arr = @tracks.models.map (model)->
        textContent: model.displayTrackArtistTitle()
        value: model.id
        selected: selected is model.id
      arr.push
        textContent: 'N/A'
        value: ''
        first: yes
      populate(el, arr)

v.set 'renderLists', (lists)->
  Object.keys(lists).forEach (key)=>
    lview = lists[key]
    lview.render()
    el = @n.getEl("[list-target='#{key}']")
    el.innerHTML = ''
    el.appendChild(lview.el)

module.exports = v.make()
