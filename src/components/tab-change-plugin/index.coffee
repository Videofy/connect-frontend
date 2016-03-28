module.exports = (config={})-> 
  { page, onQuery } = config
  (v)->
    onTabChanged = ->
      @query(@tabs.active, @needle or "", false, true)

    v.init (opts={})->
      { @router } = opts
      @tabs.on "changetab", onTabChanged.bind(@) if @router?

    v.set "open", (needle="")->
      index = needle.indexOf("/")
      index = needle.length if index is -1
      key = needle.substr(0, index)
      
      if key not of @tabs.config
        key = @tabs.active 
        query = needle
      else
        query = needle.substr(index + 1, needle.length)

      query = decodeURIComponent(query)
      @query(key, query, true, true)

    v.set "query", (view, needle, reset=true, force=false)->  
      return if needle is @needle and not force
      onQuery?.call(@, view, needle, reset)
      @needle = needle
      @updateLocation() if not @tabs.setTab(view)
    
    v.set "updateLocation", -> 
      return unless @router?
      url = "#{page}/#{@tabs.active}/#{encodeURIComponent(@needle or "")}" 
      @router.navigate url, 
        trigger: false
        replace: true
