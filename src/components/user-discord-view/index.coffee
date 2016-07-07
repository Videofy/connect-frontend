view = require("view-plugin")
eurl = require("end-point").url

UserDiscordView = v = bQuery.view()

v.use view
  className: "user-discord-view"
  template: require("./template")
  locals:
    url: eurl("/api/self/discord")

v.set "render", ->
  @renderer.render()

module.exports = v.make()
