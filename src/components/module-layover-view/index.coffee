
TemplateRenderer = require("template-renderer")

class ModuleLayoverView extends Backbone.View

  events:
    "click .modal-header > button.close": "invokeCloseAction"
    "click .modal-footer > button.btn-default": "invokeDefaultAction"
    "click .modal-footer > button.btn-primary": "invokePrimaryAction"
    "click .modal-footer > button.btn-danger": "invokeDangerAction"

  initialize: ( opts ) ->
    @renderer = new TemplateRenderer
      view: @
      template: require("./template")
    @el.classList.add("modal", "hide", "fade")
    if opts.fullsize is false
      @el.classList.remove("fullsize")
    else
      @el.classList.add("fullsize")
    @el.setAttribute("data-backdrop", "static")
    @el.setAttribute("data-keyboard", "false")
    @parent = opts.parentEl
    @body = opts.bodyView
    @actions = opts.actions || {}
    @opts = opts

  render: ->
    @renderer.render()
    @displayCloseButton(@opts.displayClose)
    @displayDefaultButton(@opts.strings.default)
    @displayPrimaryButton(@opts.strings.primary)
    @displayDangerButton(@opts.strings.danger)
    if @opts.hideHeader
      @displayHeader(false)
    if @opts.hideFooter
      @displayFooter(false)
    @setTitle(@opts.strings.title)
    @setBody(@body)

  getButtonByName: ( name ) ->
    btn = null
    switch name.toLowerCase()
      when "close" then btn = @el.querySelector(".modal-header > button.close")
      when "default" then btn = @el.querySelector(".modal-footer > button.btn-default")
      when "primary" then btn = @el.querySelector(".modal-footer > button.btn-primary")
      when "danger" then btn = @el.querySelector(".modal-footer > button.btn-danger")
    return btn

  displayCloseButton: ( value ) ->
    @displayButton(@getButtonByName("close"), value, true)

  displayDefaultButton: ( text ) ->
    @displayButton(@getButtonByName("default"), text)

  displayPrimaryButton: ( text ) ->
    @displayButton(@getButtonByName("primary"), text)

  displayDangerButton: ( text ) ->
    @displayButton(@getButtonByName("danger"), text)

  displayButton: ( btn, text, noText ) ->
    if text
      btn.classList.remove('hide')
      if not noText
        btn.innerHTML = text
    else
      btn.classList.add('hide')

  enableButton: ( name ) ->
    btn = @getButtonByName(name)
    if btn
      btn.removeAttribute('disabled')

  disableButton: ( name ) ->
    btn = @getButtonByName(name)
    if btn
      btn.setAttribute('disabled', true)

  displayHeader: ( value ) ->
    if value
      @$el.find(".modal-header").show()
    else
      @$el.find(".modal-header").hide()

  displayFooter: ( value ) ->
    if value
      @$el.find(".modal-footer").show()
    else
      @$el.find(".modal-footer").hide()

  setTitle: ( title ) ->
    @$el.find(".modal-header > h3").text(title)

  setBody: ( view ) ->
    @$el.find(".modal-body > .modal-body-content").append(view.el)

  show: () ->
    @removeOnHiddenListener()
    @$el.modal("show")

  hide: ( remove=false ) ->
    @onHiddenCallback = @onModalHidden.bind(@, remove)
    @$el.on('hidden', @onHiddenCallback)
    @$el.modal("hide")

  removeOnHiddenListener: () ->
    if @onHiddenCallback
      @$el.off('hidden', @onHiddenCallback)
      @onHiddenCallback = null

  onModalHidden: ( remove, e ) ->
    @removeOnHiddenListener()
    if remove
      @remove()

  open: () ->
    @removeOnHiddenListener()
    if @$el.parent().length == 0
      $(@parent).append(@$el)
    @show()

  close: () ->
    @hide(true)

  invokeCloseAction: ->
    @trigger "invokeCloseAction", @
    @actions.close(@)

  invokeDefaultAction: ->
    @trigger "invokeDefaultAction", @
    @actions.default(@)

  invokePrimaryAction: ->
    @trigger "invokePrimaryAction", @
    @actions.primary(@)

  invokeDangerAction: ->
    @trigger "invokeDangerAction", @
    @actions.danger(@)

module.exports = ModuleLayoverView
