Enabler        = require("enabler")
TemplateRender = require("template-renderer")
InputBinder    = require('input-binder')

module.exports = (config)-> (v)->
  v.init (opts={})->
    {@i18, @evs, @sse, @permissions, @router} = opts
    @n = new Enabler(@el)

    if config.binder
      @ib = new InputBinder(@el, @model, config.binder.mode)
      @on 'render', =>
        @ib.findAndBind(if typeof config.binder is 'string' then config.binder else config.binder.property)

  v.set("className", config.className) if config.className
  v.set("tagName", config.tagName) if config.tagName

  if config.template
    v.use(TemplateRender.plugin(config.template, config.locals))

  v.set "toast", (text, theme="default", time=2500)->
    @evs?.trigger "toast",
      time: time
      theme: theme
      text: text