debug = require('debug')('tab-activator')

module.exports = (o) ->
  return (v) ->
    v.set "activateTab", (n) ->
      $tabList = @$(o.tag || ".tabs")
      $tabs = $tabList.children()
      $tabs.removeClass("active")

      $tab = @$(".#{ n }Tab", $tabList)
      $tab.addClass("active")

      $sections = @$(o.sectionsTag || ".tab-sections").children()

      $sections.hide()
      $section = @$(".tab-#{ n }")
      @trigger "activated:tab", n
      @trigger "activated:tab:#{ n }"
      $section.show()
      o.callback(@) if o.callback

    _(o.sections || []).each (section) ->
      debug("registering .#{ section }Tab")
      v.on "click .#{ section }Tab", -> @activateTab section
