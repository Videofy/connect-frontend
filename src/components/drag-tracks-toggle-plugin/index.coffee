
module.exports = (config={})-> (v)->
  cls = config.className or "drag-active"

  v.init (opts={})->
    return if not @evs
    @evs.on "dragtracks:start", =>
      @el.classList.add(cls)
    @evs.on "dragtracks:end", =>
      @el.classList.remove(cls)
