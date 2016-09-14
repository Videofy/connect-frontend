view = require("view-plugin")
eurl = require("end-point").url

UserDiscordView = v = bQuery.view()

v.use view
  className: "user-discord-view"
  template: require("./template")

v.init (opts={})->
  { @whitelists } = opts

v.set "render", ->
  @whitelists.toPromise().then =>
    links = []

    if @whitelists.models.length
      links.push
        url: eurl("/api/self/discord/licensee")
        text: @i18.strings.phrases.discordLicensee

    if @model.hasGoldService()
      links.push
        url: eurl("/api/self/discord/gold")
        text: @i18.strings.phrases.discordGold

    @renderer.locals.links = links
    @renderer.render()

module.exports = v.make()
