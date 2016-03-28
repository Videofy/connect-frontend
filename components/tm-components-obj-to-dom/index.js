var whitelist = [
  'children',
  'key',
  'tagName',
  'attributes'
]

function create(obj){
  if (!obj.tagName) throw Error('Must provide tagName.')
  var branch = {
    el: document.createElement(obj.tagName),
    obj: obj
  }

  var el = branch.el
  Object.keys(obj).map(function (key) {
    if ( typeof el[key] != 'function' &&
      whitelist.indexOf(key) === -1 &&
      el[key] != void 0
      ) {
      el[key] = obj[key]
    }
  })

  if (obj.attributes) {
    Object.keys(obj.attributes).forEach(function (attribute) {
      el.setAttribute(attribute, obj.attributes[attribute])
    })
  }

  if (obj.children instanceof Array) {
    branch.children = obj.children.map(function (obj) {
      var abranch = create(obj)
      el.appendChild(abranch.el)
      return abranch
    })
    branch.children.forEach(function (abranch, index, arr) {
      if (abranch.obj.key && isNaN(abranch.obj.key)) {
        branch.children[abranch.obj.key] = abranch
      }
    })
  }

  return branch
}

module.exports = create