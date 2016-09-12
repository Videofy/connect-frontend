
module.exports = (config)->
  { empty, createRow, createPane } = config

  throw Error('createRow was not provided.') unless createRow

  (opts)->
    tbody = @n.getEl('.fsr tbody')
    tbody = @n.getEl('tbody') unless tbody
    return unless tbody

    empty = opts.empty || empty

    while tbody.firstChild
      tbody.removeChild(tbody.firstChild)

    if !@collection.models.length && empty
      tbody.innerHTML = empty()
      return

    frag = document.createDocumentFragment()

    models = @collection.getPage(opts)
    models.forEach (model)=>
      pane = createPane.call(@, model) if createPane
      row = createRow.call(@, model, pane)

      # For speed, dont render the pane yet since by
      # default its not visible
      # pane.render()
      row.render()

      frag.appendChild(row.el)
      frag.appendChild(pane.el) if pane

    if frag.hasChildNodes()
      tbody.appendChild(frag)

    true
