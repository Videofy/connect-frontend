marked  = require("marked")
request = require("superagent")
View    = require("view-plugin")

StylesView = v = bQuery.view()

v.use View
  className: "styles-view"
  template: require("./template")

v.set "render", ->
  @renderer.render()

v.set "open", ->
  request
    .get("/styles")
    .end (err, res) =>
      if err or res.status isnt 200
        return err or "An error occurred."

      str = marked(res.body)
      str = str.replace(/<table/g, "<table class='ss bordered'")
      @n.getEl("[role='style-guide']").innerHTML = str

module.exports = v.make()