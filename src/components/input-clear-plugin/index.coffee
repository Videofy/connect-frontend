
module.exports = (config={})-> (v)->
  selector = config.selector or ".ss.search"
  event = config.ev or "inputcleared"
  callback = config.callback

  v.init ->
    @on "render", =>
      els = @el.querySelectorAll(selector)
      for el, i in els
        input = el.firstChild
        btn = el.lastChild
        btn.addEventListener "click", (e)=>
          input.value = ""
          @trigger(event, e)
          @[callback] and @[callback](e)