hoganutil = require('hogan-util')
marked    = require('marked')
objtodom  = require('obj-to-dom')
view      = require('view-plugin')

r = (obj, el)->
  while el.firstChild
    el.removeChild(el.firstChild)
  el.appendChild(objtodom(obj).el)

v = bQuery.view()

v.use view
  className: 'review'

v.set 'renderText', (text, variables, open='👉', close='👈')->
  return @renderEmpty() unless text

  opts =
    transforms:
      dateFormat: 'F j, Y'

  try
    highlight = hoganutil.highlight(text, open, close)
    render = hoganutil.render(highlight, variables, opts)
  catch err
    return @renderError(err)

  html = marked(render)
  html = html.replace(new RegExp(open, 'g'), '<span class="variable">')
  html = html.replace(new RegExp(close, 'g'), '</span>')
  @el.innerHTML = html

v.set 'renderError', (err)->
  obj =
    tagName: 'p'
    textContent: err.message
  r(obj, @el)

v.set 'renderEmpty', ->
  obj =
    tagName: 'p'
    textContent: 'There is no contract body to preview.'
    className: 'ss center-text heavy expand'
  r(obj, @el)

module.exports = v.make()