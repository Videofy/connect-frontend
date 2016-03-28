view = require("view-plugin")

lv = bQuery.view()

lv.use view
  className: 'ss'
  tagName: 'label'

module.exports = lv.make()
