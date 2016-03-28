
bQuery.view.mixin(

  editing: ->
    return (v) ->
      v.init ->
        @on "editing:start", => @isEditing = yes
        @on "editing:end",   => @isEditing = no

#=----------------------------------------------------------------------------=#
# editable
#   editable elements bound to model fields
#     opts.click - click tag name
#     opts.render :: idAttr -> txt -> html
#=----------------------------------------------------------------------------=#
  editable: (opts={}) ->
    state = {}
    state.editing = no
    state.saving = no

    edit = opts.edit or opts.click

    return (v) ->
      # nv is new value
      # ov is old value
      # elem is current element
      finish = (rest...) ->
        return if state.saving
        state.saving = yes
        setTimeout (=> state.saving = no), 100

        if opts.update
          opts.update.call @, rest...

        state.editing = no
        @trigger "editing:#{ edit }:end", edit
        @trigger "editing:end"

      v.init ->
        @on 'render', =>
          @$(edit).addClass "clickable"

      go = (e) ->
        elem = $(e.target)
        return if state.editing is yes
        return if state.saving is yes
        state.editing = yes
        @trigger "editing:#{ edit }:start", edit
        @trigger "editing:start", edit, elem
        opts.render.call @, finish.bind(@), (->), elem

      v.on "focus " + opts.click, go
      v.on "click " + opts.click, go

#=----------------------------------------------------------------------------=#
# textboxEffects
#=----------------------------------------------------------------------------=#
  textboxEffects: (attr, click, opts={}) ->
    defaultText = opts.defaultText ?
      (v) -> if v then v else "#{ attr } not set"
    label = "label"
    warning = off
    return (v) ->
      handleDefaultText = (view, nv, $click) ->
        if nv
          nv = opts.toView(nv) if opts.toView
          dt = nv
          $click.removeClass(label)
          if warning is on
            view.model.trigger "resolved", attr, "empty"
            view.model.trigger "resolved:#{attr}", "empty"
            warning = off
        else
          warning = on
          view.model.trigger "warning", attr, "empty"
          view.model.trigger "warning:#{attr}", "empty"
          dt = defaultText(nv)
          $click.addClass(label)
        $click.text(dt)

      v.init ->
        @on "render", =>
          handleDefaultText(@, @model.get(attr), @$(click))

        @on "editing:#{click}:start", =>
          @$(click).removeClass(label)

        @on "textbox:#{attr}:done", ($click, nv) ->
          handleDefaultText(@, nv, $click)

#=----------------------------------------------------------------------------=#
# textbox
#=----------------------------------------------------------------------------=#
  textbox: (attr, click, opts={}) ->
    return (v) ->
      unless opts.noEffects
        v.textboxEffects(attr, click, opts)
      v.editbox(_.extend(opts, {
        click: click
        update: (nv) ->
          nv = opts.fromView(nv) if opts.fromView
          ov = @model.get(attr)
          @model.set(attr, nv, error: Mixins.error)
          @$(click).text(nv)
          $click = @$(click)
          @trigger "textbox:done", $click, nv
          @trigger "textbox:#{ attr }:done", $click, nv
          if opts.saveFunc
            opts.saveFunc(@, nv, ov)
          else
            @model.save {}, opts.saveHandlers or
              error: => @model.set(attr, ov)
      }))

#=----------------------------------------------------------------------------=#
# textboxes
#=----------------------------------------------------------------------------=#
  textboxes: (prefix, fields, opts={}) ->
    return (v) ->
      _(fields).each (field) =>
        bt = "#{ prefix }-#{ field }"
        v.boundText field, ".#{ bt }", opts.blank
        v.textbox field, ".edit-#{ bt }",
          defaultText: opts.blank
          editText: ($edit, model) => model.get(field)

#=----------------------------------------------------------------------------=#
# editbox
#=----------------------------------------------------------------------------=#
  editbox: (opts={}) ->
    return (v) ->
      edit = opts.edit or opts.click
      newEditIdName = edit[1..]

      idAttr =
        switch edit[0]
          when "#" then { id: newEditIdName }
          when "." then { "class": newEditIdName }
          else {}

      v.editable(_.extend(opts, {
        render: (finish, cb, elem) ->
          $edit = elem
          et = _.beta(opts.editText, $edit, @model)
          txt = if _.isNull(et) or _.isUndefined(et) then $edit.text() else et

          fin = -> finish($edit.val(), txt, elem)

          d =
            type: "text"
            value: txt

          if opts.textAsPlaceholder
            d.placeholder = txt
            d.value = ""

          input = @make("input", _.extend(d, idAttr))
          $(input).addClass(opts.inputClass) if opts.inputClass

          $edit = $("input", $edit.html(input))
          $edit.select()

          $edit.blur fin

          $edit.keydown (e) =>
            if (e.which or e.keyCode) is 13
              e.preventDefault()
              fin()
              return false

          cb($edit)
      }))

#=----------------------------------------------------------------------------=#
# editableLink
#=----------------------------------------------------------------------------=#
  editableLink: (opts={}) ->
    return (v) ->
      origUpdateModel = opts.update
      elem = opts.click
      v.editable(_.extend(opts, {

        update: (nv, ov, elm) ->
          origUpdateModel.call @, nv, ov, elm

        render: (finish, cb, elem) ->
          oldTxt = @model.get('url')
          $input = $edit = elem

          fin = ->
            finish($input.val(), oldTxt, elem)

          template = require('link').templates['link-edit']
          template = Mixins.makeAsyncTemplate(template)

          template {
            model: @model
          }, (data) =>

            $edit = @$(".release-link-container", elem)
            $edit.html(data)

            $input = @$("input", elem)

            $input.blur fin

            $input.keydown (e) =>
              if (e.which or e.keyCode) is 13
                e.preventDefault()
                fin()
                return false

            cb()
      }))

  editableStrListEx: (opts) ->
    return (v) ->
      v.editableStrList(opts.listItemTag, opts.field, opts.listTag, opts.text, opts.tag)

#=----------------------------------------------------------------------------=#
# editableStrList
#=----------------------------------------------------------------------------=#
  editableStrList: (tag, field, listTag, dispText, tags) ->
    tags ?= tag + "s"
    return (v) ->
      v.editable(
        click: tag
        update: (nv, ov, elem, deleteIt=no) ->
          if !nv?.trim()
            deleteIt = yes

          updated = nv isnt ov
          xs = @model.get(field)
          shouldReject = _.anyThen ((cid) -> cid is ov), _.just(false)
          xs = _(xs).reject shouldReject

          reset = ->
            elem.text(nv)
            elem.addClass("clickable")

          saveD = {}
          saveD[field] = xs

          if deleteIt
            elem.hide()
            return @model.save saveD,
                     error: (xs...) ->
                       elem.show()
                       reset()
                     success: -> elem.remove()

          reset()

          if updated
            xs.push(nv)
            @model.save saveD,
              error: (xs...) ->
                elem.text(ov)
              success: ->

        render: (finish, cb, elem) ->
          template = Views.templates.get("edit-textbox")
          ov = elem.text()
          template {
            model:
              txt: ov
          }, (data) =>
            elem.removeClass("clickable")
            elem.html(data)
            $input = $("input", elem)
            timer = null

            fin = =>
              clearTimeout timer if timer
              finish($input.val(), ov, elem)

            cancel = => finish(ov, ov, elem)

            @$(".ok", elem).click fin
            @$(".cancel", elem).click cancel
            @$(".delete", elem).click =>
              finish(null, ov, elem, yes)

            $input.enter fin
            $input.focusout =>
              timer = setTimeout(cancel, 500)

            cb()
      )
      .editbox(
        click: tags
        textAsPlaceholder: true
        update: (nv) ->
          elem = @$(tags)
          if nv.trim() 
            xs = @model.get(field) or []
            xs.push nv
            d = {}
            d[field] = xs
            @model.save d,
              success: (b) => @$(listTag).append(@make "li", {
                "class": "#{ tag[1..] } clickable"
              }, nv)
          elem.text(dispText)
      )


#=----------------------------------------------------------------------------=#
# Mixins.editableDate
#=----------------------------------------------------------------------------=#
  editableDate: (opts={}) ->
    return (v) ->
      v.editable(_.extend(opts, {
        render: (finish, cb) ->

          template = Views.templates.get("datepicker")

          checkDate = (d) ->
            if isNaN(d.getTime()) then null else d

          date = checkDate(new Date(@$(opts.click)[0].innerHTML)) || new Date()

          template {
            day: ->
              if date.getDate() < 10 then '0'+date.getDate() else date.getDate()
            month: ->
              month = date.getMonth() + 1 #date.getMonth() returns number 0-11
              if month < 10 then '0'+ month else month
            year: -> date.getFullYear()
          }, (data) =>
            $edit = @$(opts.click)
            $edit.html(data)
            $datepicker = $(".date", $edit)
            $datepicker.datepicker()
              .on 'changeDate', (e) ->
                finish(new Date e.date)
                $('.datepicker').remove()
            $(".add-on", $edit).trigger('click')
            cb()
      }))

#=----------------------------------------------------------------------------=#
# editableArtists
#=----------------------------------------------------------------------------=#
  editableArtists: (opts={}) ->
    UserCollection = require('user-collection')
    return (v) ->
      origUpdateModel = opts.update
      elem = opts.select or opts.click
      v.editable(_.extend(opts, {
        update: (nv) ->
          e = @$(elem)
          selected = $("select option:selected", e)
          items = (selected.map (ind, s) ->
            $s = $(s)
            name: $s.text()
            artistId: $s.val()
          ).get()

          origUpdateModel.call @, items

        render: (finish, cb) ->
          template = Views.templates.get("select")
          selected = _(@model.get(opts.type or "artists")).map (a) -> a.artistId
          # selected = _(@artists).map (a) -> a.artistId
          artists = new UserCollection
          artists.fetch
            success: (arts) =>
              template {
                model: arts.models
                extra:
                  multiple: yes
                  isSelected: (art) ->
                    selected.indexOf(art.id) isnt -1
                  value: (art) -> art.id
                  text: (art) -> art.get("name")
              }, (data) =>
                $edit = @$(elem)
                $edit.html(data)
                Mixins.chosen(finish, $edit)
                cb()
      }))

#=----------------------------------------------------------------------------=#
# editableTracks
#=----------------------------------------------------------------------------=#
  editableTracks: (opts={}) ->
    TrackCollection = require('track-collection')
    return (v) ->
      origUpdateModel = opts.update
      elem = opts.show or opts.click
      v.editable(_.extend(opts, {
        update: (nv) ->
          e = @$(elem)
          selected = $("select option:selected", e)

          items = (selected.map (ind, s) ->
            $s = $(s)
            title: $s.text()
            trackId: $s.val()
          ).get()

          origUpdateModel.call @, items
        render: (finish, cb) ->
          template = Views.templates.get("select")
          selected = _(@model.get(opts.type or "")).map (a) -> a.trackId
          tracks = @tracks or new TrackCollection
          tracks.fetch
            success: (tracks) =>
              @tracks = tracks
              template {
                model: tracks.models
                extra:
                  multiple: yes
                  isSelected: (tracks) ->
                    selected.indexOf(tracks.id) isnt -1
                  value: (tracks) -> tracks.id
                  text: (tracks) -> tracks.get("title")
              }, (data) =>
                $edit = @$(elem)
                $edit.html(data)
                Mixins.chosen(finish, $edit)
                cb()
      }))

#=----------------------------------------------------------------------------=#
# editableSelect
#=----------------------------------------------------------------------------=#
  editableSelect: (opts={}) ->
    multiple = opts.multiple or no
    return (v) ->
      unless opts.bound is no
        v.boundText opts.field, opts.click, (xs=[]) ->
          return "none set" if xs.length is 0
          if opts.multiple then xs.join ", " else xs

      v.editable(_.extend(opts,
        update: (nv) ->
          $type = @$(opts.click)

          base = $("select option:selected", $type)
          if opts.multiple
            if opts.multipleVals
              type = opts.multipleVals(base)
            else
              type = _(base.toArray()).map (x) -> $(x).text()
          else
            if opts.value? then type = base.val() else type = base.text()

          base = $("select option:selected", $type)
          if (not opts.oneRequired) or (base.toArray().length > 0)
            @model.set opts.field, type, { silent: true }
            @model.trigger "change:#{ opts.field }", @model, type
            if opts.save?
              opts.save.call @, type
            else
              @model.save()

        render: (finish, cb, $edit) ->
          $edit = @$(opts.click)
          template = Views.templates.get("select")
          mtype = @model.get(opts.field)

          go = (items) ->
            template {
              model: items
              extra:
                multiple: multiple
                selected: mtype
                isSelected: opts.isSelected or (type) =>
                  if multiple
                    type in mtype
                  else
                    type is mtype
                value: opts.value or _.id
                text: opts.text or _.id
            }, (data) =>
              $edit.html(data)
              Mixins.chosenDropdown finish, $edit, cb

          if opts.asyncItems
            opts.asyncItems go
          else
            go _.beta.call(@, opts.items)
      ))
)
