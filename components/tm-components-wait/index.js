module.exports = function wait (time, context, done) {
  var waiting = true
  var fired = false
  var args = []

  function wrapper () {
    fired = true
    if (!waiting) return done.apply(context, arguments)
    args = Array.prototype.slice.call(arguments)
  }

  function dispatch () {
    waiting = false
    if (fired) wrapper.apply(context, args)
  }

  setTimeout(dispatch, time)

  return wrapper
}