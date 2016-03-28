
module.exports = (config={}) ->
  return (v) ->
    v.init ( opts ) ->
      @render = (cb) ->
        go = (html) =>
          x = if config.html then config.html.call(@, html, @model) else html

          @$el.html(x)
          @trigger "render"
          cb?(@)

        if config.template
          config.template.call @, go
        else if !config.noModel and @model
          d = {}
          d.model = @model
          d.model = d.model.toJSON() unless config.rawModel
          _(d).extend(_.beta.call @, config.templateData || opts.templateData )
          @template.call @, d, go
        else
          d = _.beta.call @, config.templateData
          @template.call @, d or {}, go
        @

