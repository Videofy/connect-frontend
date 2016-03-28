function getType (item) {
  if (item instanceof Array) return 'array'
  return typeof item
}

function unique (arr) {
  var cache = []
  arr.forEach(function (item) {
    if (cache.indexOf(item) == -1) cache.push(item)
  })
  return cache
}

function areSameTypeOfArrays (a, b) {
  var atypes = unique(a.map(getType))
  var btypes = unique(b.map(getType))
  return atypes.length == 0 || atypes.join() == btypes.join()
}

function mergeArrays (a, b) {
  for (var i=0; i<b.length; i++) {
    if (!a[i]) {
      a[i] = b[i]
      continue
    }

    a[i] = merge(a[i], b[i])
  }
  return a
}

function mergeObject (dest, src) {
  Object.keys(dest).forEach(function (key) {
    dest[key] = merge(dest[key], src[key])
  })
  return dest
}

function merge (a, b) {
  if (a instanceof Date && b instanceof Date) {
    a.setTime(b.getTime())
  }
  else if (a instanceof Array && b instanceof Array) {
    if (areSameTypeOfArrays(a, b)) return mergeArrays(a, b)
  }
  else if (typeof a == 'object' && typeof b == 'object') {
    return mergeObject(a, b)
  }
  else if (typeof a == typeof b) {
    return b
  }

  return a
}

module.exports = merge