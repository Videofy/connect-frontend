view = require("view-plugin")
eurl = require("end-point").url

UserDiscordView = v = bQuery.view()

v.use view
  className: "user-discord-view"
  template: require("./template")

v.set "render", ->
  @renderer.render()
 
module.exports = v.make()
