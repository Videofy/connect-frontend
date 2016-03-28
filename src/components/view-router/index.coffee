class ViewRouter

  constructor: (@router, @events)->

  set: (@el, @routes)->
    for name, opts of @routes
      @router.route(opts.pattern, name, @show.bind(@, name))

  show: ->
    name = arguments[0]
    route = @routes[name]

    return if !route

    redirect = route.redirect() if route.redirect
    return @router.navigate(redirect, trigger:true) if redirect

    if @active != name
      @routes[@active].view.el.remove() if @active
      @active = name

      if !route.view
        route.view = route.create()
        route.view.render()

    view = @routes[name].view
    params = Array.prototype.slice.call(arguments, 1, arguments.length)

    view.open and view.open.apply(view, params)
    @el.appendChild(view.el)
    @events.trigger("page", name)
    @router.trigger("route", name, params) # NOTE New Backbone already has this.

module.exports = ViewRouter
