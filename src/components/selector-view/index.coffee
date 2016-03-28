
mkSelector = () ->

  v = bQuery.view()

  v.init (opts={}) ->
    @collection = opts.collection
    @on "render", => @build(opts)
    @collection.on 'sync reset add remove', =>
      @build(opts)

  v.set "build", (opts={})->
    models = opts.filter?(@collection.models) ? @collection.models

    data = _(models).map (model)->
      id: model.id or model.get(opts.id)
      text: model.get(opts.text)

    @$(".selector").select2
      placeholder: opts.placeholder,
      data:data
      initSelection: (element,callback)=>
        d = []
        o = _.find(data,(ele)-> ele.id ==element.val())
        d.push(o)
        callback(d)
      # multiple:true

    @$(".selector").addClass(opts.classes)

  v.set "clear", (opts={})->
    @$(".selector").select2("val", "")

  v.defaults 'selector',
    noModel: yes

  v.on 'change .selector', (e)->
    @trigger 'change', e.val

  v.make()

module.exports = mkSelector
