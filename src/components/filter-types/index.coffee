
module.exports = (opts={}) ->
  return (v) ->
    v.set "filterType", (type) ->
      tag = opts.tab?(type) ? ".#{ type }-tab"
      $(@el.querySelector(tag)).button('toggle')
      # Why are we mixing filter-types and filterables here?!
      @siftFilterable(opts?.types[type] ? opts.default(type))
