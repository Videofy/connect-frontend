bound                = require('bquery-binders')
releasemenu          = require("release-context-menu-plugin")
view                 = require("view-plugin")
rowView              = require("row-view-plugin")
disabler             = require('disabler-plugin')

onClickLink = (e)->
  e.stopPropagation()

onClickDelete = (e)->
  e.stopPropagation()
  title = @model.get('title')
  msg = @i18.strings.defaults.destroyMsg.replace(/\{.+\}/, title)
  return unless window.confirm(msg)

  @model.destroy
    wait: true
    success: (model, res, opts)=>
      @evs.trigger 'toast',
        time: 2500
        theme: 'success'
        text: "The release \"#{title}\" has been removed."
    error: (model, res, opts)=>
      @evs.trigger 'toast',
        time: 2500
        theme: 'error'
        text: JSON.parse(res.responseText).message

ReleaseRowView = v = bQuery.view()

v.use view
  tagName: "tr"
  className: "pane-row release-row-view"
  template: require("./template")

v.ons
  "click [role='delete']": onClickDelete
  "click [role='link']": onClickLink

v.init (opts={})->
  @listenTo(@model, "change", @updateInterface.bind(@))

v.use rowView

v.use releasemenu
  ev: "click [role='download']"
  from: "ReleaseRowView"
  getRelease: -> @model

v.use disabler
  attribute: 'editable'
v.set 'render', ->
  @renderer.render()
  @updateActions()
  @updateText()

v.set 'updateInterface', ->
  @updateActions()
  @updateText()

# This really just shows if needs to be repackaged now.
v.set 'updateStatus', (status='unknown')->
  attr = 'package-status'
  @n.getEl("[role='#{attr}']").setAttribute(attr, status)

v.set 'updateText', ->
  @n.setText("td.release-details > .release-title", @model.get("title"))
  @n.setText("td.release-details > .artist-names",
    @model.get("renderedArtists"))
  @n.setText("td.type", @model.get("type"))
  @n.setText("td.release-date", @model.getAsFormatedDate("releaseDate"))
  @n.setText("td.catalog-number", @model.get("catalogId") or "")

  status = if @model.get('dirty') then 'dirty' else 'finished'
  @updateStatus(status)

v.set 'updateActions', ->
  @n.evaluateClass('[role="delete"]', 'hide', @permissions.canAccess('release.destroy'))

module.exports = v.make()
