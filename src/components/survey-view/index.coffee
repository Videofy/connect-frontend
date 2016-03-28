view = require("view-plugin")
v    = bQuery.view()

sel =
  doSurvey: "[role='do-survey']"
  content: "[role='survey-content']"
  option: "[role='option']"

v.use view
  className: 'sub-survey-view'
  template: require("./template")

v.init (opts={}) ->
  @user = opts.user
  @router = opts.router
  @loaded = false


v.set "render", ->
  if @user.isOfTypes ["golden"]
    @renderer.locals.surveyLink = "https://www.surveymonkey.com/r/B7KML3Q"
  else
    @renderer.locals.surveyLink = "https://www.surveymonkey.com/r/W9JQ2J6"

  @renderer.render()

module.exports = v.make()
