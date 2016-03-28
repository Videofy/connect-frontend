var hogan = require('hogan.js')
var format = require('date-time').format

var util = {
  validate: function validate (tree, variables, root) {
    if (!(variables instanceof Array)) variables = [variables]

    for (var n=0; n<variables.length; n++) {
      var vars = variables[n]
      for (var i=0; i<tree.length; i++) {
        var branch = tree[i]

        if (branch.tag == '_v' && vars[branch.n] == void 0) {
          return Error('The "' + (root || "root") +
            '" branch is missing variable named "' +
            branch.n + '" in an item.')
        }

        if (branch.tag == "#" && vars[branch.n]) {
          var err = util.validate(branch.nodes, vars[branch.n], branch.n)
          if (err) return err
        }
      }
    }
  },

  tree: function tree (text) {
    return hogan.parse(hogan.scan(text))
  },

  treeToObject: function treeToObject (tree) {
    var obj = {}

    for (var i=0; i < tree.length; i++) {
      var branch = tree[i];
      // Handle case where displaying value only.
      if (branch.tag == '_v') obj[branch.n] = ""

      // Handle case where we are displaying listed nested values.
      if (branch.tag == '#') obj[branch.n] = [util.treeToObject(branch.nodes)]
    }

    var keys = Object.keys(obj)

    for (var i = 0; i < keys.length; i++) {
      var key = keys[i]
      var value = obj[key]

      if (!(value instanceof Array) || value.length == 0) continue

      var first = value[0]
      var subkeys = Object.keys(first)

      // Handle case where using variable as boolean value only.
      if (subkeys.length == 0)
        obj[key] = false

      // Handle case where checking if variable exists to display it.
      if (subkeys.length == 1 && subkeys[0] == key)
        obj[key] = first[subkeys[0]]
    }

    return obj
  },

  isRenderable: function isRenderable (text, variables) {
    var tree
    try {
      tree = util.tree(text)
    }
    catch (e) {
      return e
    }
    return util.validate(tree, variables)
  },

  render: function render (text, variables, opts) {
    if (opts && opts.transforms && typeof opts.transforms == 'object')
      variables = transformObject(variables, opts.transforms)

    return hogan.compile(text).render(variables)
  },

  highlight: function highlight (text, open, close) {
    if (text == undefined) throw Error('No text provided.')
    if (open == undefined) throw Error('No open tag provided.')
    if (close == undefined) close = open

    return highlightBranches(util.tree(text), {
      text: text.toString(),
      open: open,
      close: close
    })
  },

  hogan: hogan
}

function transformValue (value, opts) {
  if (value instanceof Array) return transformArray(value, opts)
  if (value instanceof Date && opts.dateFormat)
    return format(opts.dateFormat, value)
  if (typeof value == 'object')
    return transformObject(value, opts)
  return value
}

function transformArray (arr, opts) {
  return arr.map(function (item) {
    return transformValue(item, opts)
  })
}

function transformObject (obj, opts) {
  var tmp = {}
  Object.keys(obj).forEach(function (key) {
    tmp[key] = transformValue(obj[key], opts)
  })
  return tmp
}

function insertChar(str, character, position) {
  return str.substr(0, position) + character + str.substr(position)
}

function highlightBranches (branches, opts) {
  if (opts.offset == undefined || isNaN(opts.offset)) {
    opts.offset = 0
  }

  branches.forEach(function (branch) {
    if (branch.tag == '_v') {
      var str = opts.text
      var offset = opts.offset
      str = insertChar(str, opts.close, offset + branch.i)
      str = insertChar(str, opts.open, offset +
        branch.i - branch.n.length - branch.otag.length - branch.ctag.length)
      opts.offset = offset + opts.open.length + opts.close.length
      opts.text = str
    }
    else if (branch.tag == '#' && branch.nodes) {
      highlightBranches(branch.nodes, opts)
    }
  })

  return opts.text
}

module.exports = util