ContextMenuView = require("context-menu-view")

module.exports = (config={})-> (v)->
  name = config.name or "contextMenu"
  evs = if config.evs instanceof Array then config.evs else []
  evs.push(config.ev) if config.ev
  evs.push("contextmenu") if !evs.length

  v.init (opts={})->
    @[name] = new ContextMenuView

    evs =
      open: @onOpenContextMenu
      select: @onSelectContextMenu
      close: @onCloseContextMenu

    for key, value of evs
      if config[key] and typeof config[key] is "function"
        cb = config[key]
      else if config[key]
        cb = @[config[key]]
      else
        cb = value

      @[name].on(key, cb.bind(@)) if cb

  evs.forEach (ev)->
    v.on ev, (e)->
      e.preventDefault()
      e.stopPropagation()
      @[name].open(e.clientX, e.clientY, e.target)
