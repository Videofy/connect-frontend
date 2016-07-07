view  = require('view-plugin')
UserClaimsView = v = bQuery.view()

sel =
  removeChannel: "[role='remove-channel']"
  ytLink: "[role='youtube-link']"
  error: "[role='error']"
  info: "[role='info']"
  loading: "[role='loading']"

v.use view
  className: "user-claims-view"
  template: require('./template')
  binder: 'property'

v.set 'render', ->
  @renderer.render()

v.on "click #{sel.removeChannel}", (e)->
  link = @el.querySelector(sel.ytLink).value
  @n.evaluateClass(sel.loading, "hide", false)

  @model.removeClaims link, (err, removedClaims)=>
    @n.evaluateClass(sel.loading, "hide", true)

    if removedClaims and !err
      if(removedClaims.length > 0)
        claimsIds = _.map removedClaims, (item)-> item.id
        claimIds = claimsIds.join(',')
        len = claimsIds.length
        info = "The claim" + (if len == 1 then "" else "s") + "  #{claimIds} on your video " + (if len == 1 then "has" else "have") + " been removed."
      else
        info = "No claims were found on that video."
      @n.evaluateClass(sel.info, "hide", false)
      @n.setText(sel.info, info)

    @displayError(err)

v.set 'displayError', ( err ) ->
  @n.evaluateClass(sel.error, "hide", !err)
  @n.setText(sel.error, err) if err

module.exports = v.make()
