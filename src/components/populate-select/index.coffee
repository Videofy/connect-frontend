sort = require('sort-util')

module.exports = (select, list, transform, csort)->
  frag = document.createDocumentFragment()
  list = list.map(transform) if transform?
  list.filter (obj)->
      return false if typeof obj is 'string' and not obj
      !!obj.textContent
    .sort csort or (a, b)->
      return -1 if a.first and not b.first
      return 1 if b.first and not a.first
      sort.stringsInsensitive(a.textContent, b.textContent)
    .forEach (obj)->
      option = document.createElement('option')
      if typeof obj is 'string'
        option.value = option.textContent = obj
      else
        for key, value of obj
          option[key] = value
      frag.appendChild(option)
  select.appendChild(frag)
