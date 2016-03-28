countries        = require('countries')
parseError       = require('parse').superagent
querystring      = require('querystring')
request          = require("superagent")
userWhitelist    = require("user-whitelist")
passwordToggle   = require("password-toggle-plugin")
view             = require("view-plugin")

sel =
  error: "[role='error']"
  input:
    email: "[property='email']"
    realName: "[property='realName']"
    password: "[property='password']"
    location: "[property='location']"
  btn:
    create: "[role='update']"

onClickSwitchType = (e)->
  el = e.currentTarget.parentElement.parentElement.lastChild.firstChild
  istwitch = el.getAttribute("property") is "twitch"
  strings = @i18.strings.channelTypes

  el.setAttribute("property", if istwitch then "youtube" else "twitch")
  el.setAttribute("placeholder",
    if istwitch then strings.youtubeDesc else strings.twitchDesc)

onKeyUp = (e)->
  @onClickCreate(e) if e.keyCode is 13

onChangeWhitelist = (name)->
  return ( e ) ->

    if @keyupTimer
      clearTimeout(@keyupTimer)
      delete @keyupTimer

    value = e.target.value
    return if !value

    call = =>
      userWhitelist.validate name, value, (err, id)=>
        # validate parses ids from urls, make sure we set it afterwards
        @$(sel.input[name]).val(id) if id
        @displayError(err)

    @keyupTimer = setTimeout(call, 300)

SignupView = v = bQuery.view()

v.use view
  className: "sign-up-view"
  template: require("./template")

v.use passwordToggle
  selector: "[role='show-password']"
  className: "active"
  el: "[property='password']"

v.on "change [role='switch-type']", onClickSwitchType
v.on "click #{sel.btn.create}", "create"
v.on "keyup input[type='text']", onKeyUp
v.on "keyup #{sel.input.twitch}", onChangeWhitelist("twitch")
v.on "keyup #{sel.input.youtube}", onChangeWhitelist("youtube")
v.on "click [role='youtube-help']", ->
  alert("You can find your YouTube Channel Id under the advanced account settings page on the YouTube website.")

v.init (opts={})->
  { @router, @session } = opts

v.set "open", (uri="")->
  @code = uri.split('?')[0]
  @render()

v.set "render", ->
  @renderer.locals.mode = "loading"
  @renderer.render()

  return unless @code

  request
  .post '/user/get-info'
  .send code: @code
  .end ( err, res ) =>
    error = err if err
    error = res.body.error if res.status isnt 200
    if error
      @renderer.locals.mode = "error"
      @renderer.render()
      @displayError(error)
      return

    @userInfo = res.body
    @renderer.locals.mode = "view"
    @renderIt()

v.set "renderIt", ->
  @displayWhitelist()
  @renderer.locals.countries = countries.map (country)-> country.name
  @renderer.render()

  @displayError()
  @preFill()

v.set "displayWhitelist", ->
  @hasWhitelist = @userInfo.types?.indexOf("licensee") isnt -1

  if @hasWhitelist
    sel.input.twitch = "[property='twitch']"
    sel.input.youtube = "[property='youtube']"

  @renderer.locals.hasWhitelist = @hasWhitelist
  @renderer.locals.channelNum = @userInfo.plan.channelNum

v.set "preFill", ->
  return unless @userInfo.email
  @email = @userInfo.email
  @n.setText(sel.input.email, @email)

v.set "clearInputErrors", ->
  for k, v of sel.input
    @n.evaluateClass(v, "error", false)
  @displayError()

v.set "displayError", (error)->
  @n.evaluateClass(sel.error, "hide", !error)
  @n.setText(sel.error, error)

v.set "create", ->
  opts =
    code: @code
    email: @n.getValue(sel.input.email)
    location: @n.getEl(sel.input.location).value
    name: @n.getValue(sel.input.realName)
    password: @n.getValue(sel.input.password)
    realName: @n.getValue(sel.input.realName)
    whitelist: []

  if @hasWhitelist
    twitchEls = @el.querySelectorAll(sel.input.twitch)
    for twitchEl in twitchEls
      if twitch = twitchEl.value
        opts.whitelist.push
          name: "twitch"
          identity: twitch
          active: true

    youtubeEls = @el.querySelectorAll(sel.input.youtube)
    for youtubeEl in youtubeEls
      if youtube = youtubeEl.value
        opts.whitelist.push
          name: "youtube"
          identity: youtube
          active: true

  @clearInputErrors()
  @n.evaluateClass("waiting", true)

  request
  .post("/user/verify")
  .send(opts)
  .end (err, res)=>
    @n.evaluateClass("waiting", false)

    if err = parseError(err, res)
      if selector = sel.input[err.property]
        @n.evaluateClass(selector, "error", true)
        err.message = err.message.replace(err.property,
          @n.getEl(sel.input[err.property]).getAttribute("placeholder"))
      return @displayError(err.message)

    @login(opts.email, opts.password)

v.set "login", ( email, password )->
  @n.evaluateClass("waiting", true)
  @session.authenticate email, password, ( err ) =>
    @n.evaluateClass("waiting", false)
    return alert(err) if err
    @router.open("/")

module.exports = v.make()
