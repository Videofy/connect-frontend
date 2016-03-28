getLocals = (locals, opts)->
  data =
    if typeof locals is "function"
      locals.call(@)
    else if typeof locals is "object"
      _.clone(locals)
    else
      {}
  data.strings = (opts.i18 or {}).strings if !data.strings
  data.permissions = opts.permissions if !data.permissions
  data.model = @model if !data.model
  data.collection = @collection if !data.collection
  data

class TemplateRenderer
  constructor: (opts={})->
    { @template, @el, @evs } = opts

    # @locals should be an object you can manipulate.
    @locals = {}

    # @clocals is a object that gets processed at render time.
    @clocals = opts.locals

    # DEPRECIATED Implemented for legacy use.
    if opts.view
      @evs = opts.view
      @el = opts.view.el
      @locals.collection = opts.view.collection if !@locals.collection
      @locals.model = opts.view.model if !@locals.model

  render: ->
    compiled =
      if typeof @clocals is "function"
        @clocals()
      else if typeof @clocals is "object"
        @clocals
      else
        {}

    @el.innerHTML = @template(_.extend(_.clone(@locals), compiled))
    @evs?.trigger("render")

TemplateRenderer.plugin = (template, locals)-> (v)->
  v.init (opts={})->
    @renderer = new TemplateRenderer
      evs: @
      el: @el
      template: template
      locals: getLocals.bind(@, locals, opts)

module.exports = TemplateRenderer