View = require("view-plugin")
rowView = require("row-view-plugin")

LabelRowView = v = bQuery.view()

v.use View
  className: "pane-row"
  tagName: "tr"
  template: require("./template")

v.use rowView

v.set "render", ->
  @renderer.render()

module.exports = v.make()
