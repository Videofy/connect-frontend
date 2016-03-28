eurl       = require('end-point').url
marked     = require("marked")
request    = require("superagent")
View       = require("view-plugin")

HandbookView = v = bQuery.view()

v.use View
  className: "handbook-view"
  template: require("./template")

v.init (opts={})->
  { @session } = opts

v.set "render", ->
  @renderer.locals.mode = "loading"
  @renderer.render()

v.set "open", (url)->
  request
    .get(eurl("/handbook/#{url or ""}"))
    .withCredentials()
    .end (err, res)=>
      return err if err
      if res.status isnt 200
        return res?.body?.error or "An error occured."

      if @session.user is undefined
        @renderer.locals.mode = "signed-out"
        @n.evaluateClass(@el, "welcome", true)
      else
        @renderer.locals.mode = "view"
      @renderer.render()

      @n.setHtml(".content", marked(res.text))

module.exports = v.make()
