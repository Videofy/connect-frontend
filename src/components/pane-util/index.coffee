
class PaneUtil

PaneUtil.fragmentsFromCollectionListing = ( listing ) ->
  els = []
  groups = listing.getViews()
  for views in groups
    fragment = document.createDocumentFragment()
    for name, view of views
      if view.el.parentElement
        fragment.appendChild(view.el)
    fragment.model = views.default.model
    els.push(fragment)
  els

module.exports = PaneUtil
