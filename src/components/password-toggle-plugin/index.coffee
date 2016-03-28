
module.exports = (config={})-> (v)->
  { selector, className, el } = config
  throw Error "Please supply selector object" unless config.selector
  throw Error "Please supply className object" unless config.className
  throw Error "Please supply element object" unless config.el

  togglePassword = (type, active) ->

    faIcon = @n.getEl("[role='show-password']")
    element = @n.getEl(el)
    type = element.getAttribute("type")

    if type is "password"
      element.setAttribute("type", "text")
      faIcon.classList.add("active")
      active = true
    else 
      faIcon.classList.remove("active")
      element.setAttribute("type", "password")
      active = false
    @n.evaluateClass(selector, className, active)

  v.on "click #{config.selector}", togglePassword
 
