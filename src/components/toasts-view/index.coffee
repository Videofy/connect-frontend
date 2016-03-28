View = require("view-plugin")
toast_template = require("./toast-template")

ToastsView = v = bQuery.view()

v.use View
  className: "toasts-view"

v.init (opts={})->
  @evs.on "toast", @add.bind(@)
  @que = []

v.set "add", (toast)->
  @que.push(toast)
  @check()

v.set "check", ->
  return if @waiting or not @que.length
  @display(@que.shift())

v.set "display", (toast)->
  @waiting = true

  parent = @el
  el = document.createElement("div")
  el.className = "toast-view ss"
  el.innerHTML = toast_template(toast)
  el.classList.add("bg-#{toast.theme}") if toast.theme
  el.classList.add("closable")

  parent.appendChild(el)
  setTimeout =>
    el.classList.add("active")
  , 50

  remove = =>
    clearTimeout(@timer)
    el.classList.remove("active")
    setTimeout =>
      @waiting = false
      el.parentElement.removeChild(el) if el.parentElement
      @check()
    , 250

  click = (e)->
    el.removeEventListener("click", click)
    remove()
  el.addEventListener("click", click)

  @timer = setTimeout(remove, toast.time) if toast.time

module.exports = v.make()