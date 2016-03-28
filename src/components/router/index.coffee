class Router extends Backbone.Router

  download: ( href ) ->
    window.open(href, "_blank")

  reload: ->
    location.reload()

  # Open a route by loading the page from scratch.
  open: ( name ) ->
    href = ""
    if name isnt "/"
      href = "/"
      if !Backbone.history.options.pushState
        href += "#"
    location.href = href + name
    setTimeout(@reload.bind(@), 500)

module.exports = Router