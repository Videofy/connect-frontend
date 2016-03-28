
co = require('codom')

v = bQuery.view()

v.asyncrender (cb)->
  view = co.node 'input',
    type: 'hidden'
    value: @selected.join ", "
    style: "width: 300px"

  cb view

v.set("selectEl", -> @$("input"))
v.set "build", (opts={}) ->
  $select2 = @selectEl()
  $select2.select2
    tags: @tags or []
    tokenSeparators: opts.separators or [",", " "]

  if opts.readonly
    $select2.select2("disable")

  $select2.on "change", (e) =>
    @selected = e.val
    check = (p) => @trigger p, e[p].text if e[p]?
    check "added"
    check "removed"
    @trigger "change", e.val

v.set("val", -> @selected)

v.init (opts={}) ->
  { @selected, @tags } = opts
  @selected ?= []
  @on "render", => @build opts

module.exports = v.make()
