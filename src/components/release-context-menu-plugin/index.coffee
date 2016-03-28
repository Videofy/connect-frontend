formats = require("formats").defaults
menu    = require("context-menu-plugin")
request = require("superagent")

module.exports = (config={})-> (v)->
  v.use menu
    name: config.name or "releaseContextMenu"
    ev: config.ev
    open: (source, menu)->
      return unless release = config.getRelease?.call(this, source)

      items = formats.map (format)->
        name: format.name
        anchor:
          download: true
          url: release.packageUrl(format.type, format.quality)
          target: "_blank"

      menu.setItems(items)
