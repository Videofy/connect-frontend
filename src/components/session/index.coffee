Emitter = require("emitter")
request = require("superagent")
lens    = require('dot-lens')

canAccessPath = (obj, path)->
  f = lens(path)
  value = null
  try
    value = f.get(obj)
  catch e
    value = null
  return false unless value
  if typeof value is 'object'
    keys = Object.keys(value)
    return false unless keys.length
    return !!(_.find(keys, (key)-> !!value[key]))
  return !!value

canAccess = ->
  obj = arguments[0]
  paths = Array.prototype.slice.call(arguments, 1, arguments.length)
  return false unless obj and paths and paths.length
  for path, i in paths
    return yes if canAccessPath(obj, path)
  no

createPermissions = (obj)->
  obj.canAccess = canAccess.bind(obj, obj)
  obj

class Session

  constructor: ( opts={} ) ->
    { @urlRoot } = opts
    @set(opts)
    @events = new Emitter()

  set: ( opts={} ) ->
    { @user, @label, @subscription } = opts
    @permissions = createPermissions(opts.permissions) if opts.permissions

  isAuthenticated: ->
    !!(@user and @label)

  url: (str)->
    return (@urlRoot or '') + str

  load: (done)->
    request
      .get(@url('/api/self/session'))
      .withCredentials()
      .end ( err, res ) =>
        return done(err) if err
        try
          obj = JSON.parse(res.text)
        catch e
        if !obj
          return done
            error: "parse-error"
            message:"Unable to parse session data."
        @set(obj)
        done()

  loadAndAuthenticate: (done)->
    @load (err)=>
      @events.emit("authenticated") if @isAuthenticated()
      done(err)

  authenticate: ( email, password, done ) ->
    request
      .post(@url("/signin"))
      .withCredentials()
      .send
        email: email
        password: password
      .end ( err, res ) =>
        return done(res.body, res) if res.status isnt 200
        @loadAndAuthenticate(done.bind(null, err, res))

  verifyToken: (token, done)->
    request
      .post(@url("/signin/token"))
      .withCredentials()
      .send
        token: token
      .end ( err, res ) =>
        return done(res.body, res) if res.status isnt 200
        @loadAndAuthenticate(done.bind(null, err, res))

  resendToken: (done)->
    request
      .post(@url("/signin/token/resend"))
      .withCredentials()
      .end ( err, res ) =>
        return done(res.body, res) if res.status isnt 200
        done(null, res)

  destroy: ( done ) ->
    request
      .post(@url("/signout"))
      .withCredentials()
      .end ( err, res ) =>
        success = res.status is 200
        if success
          @set()
          @events.emit("unauthenticated")
        done(success)

module.exports = Session
