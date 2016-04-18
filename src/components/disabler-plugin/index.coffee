
plugin = (config)->
  attribute = config.attribute or 'editable'

  (v)->
    render = ->
      return unless @permissions
      arr = Array::slice.call(@el.querySelectorAll("[#{attribute}]"))
      arr.forEach (el)=>
        el.disabled = not @permissions.canAccess(el.getAttribute(attribute))

    v.init ->
      @on 'render', render.bind(@)

module.exports = plugin
