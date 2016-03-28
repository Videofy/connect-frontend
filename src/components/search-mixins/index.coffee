
module.exports =
  button: (opts={}) ->
    opts.tag ?= "#filter"

    return (v) ->
      v.init (os) ->
        @on "render", =>
          @$filter = @$el.find(opts.tag)
          @$filterClose = @$el.find(".search-close")

      v.on "click .search-close", ->
        @$filter.val("")
        @$filterClose.invisible()
        opts.reset.call(@)

      v.on "keyup #{ opts.tag }", ->
        if @$filter.val() is ""
          @$filterClose.invisible()
        else
          @$filterClose.visible()

