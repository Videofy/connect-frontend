Connect = Connect or {}
Connect.collection = {}
Connect.collection.table = {}

do ->
  collection = require('bquery-collection')
  bQuery.view.mixin 'collection', collection

  Connect.collection.table.element = () ->
    frag = document.createDocumentFragment()
    head = document.createElement('tr')
    body = document.createElement('tr')
    bodyTd = document.createElement('td')
    bodyTd.setAttribute('colspan', 100)
    body.appendChild(bodyTd)
    head.className = 'row-head'

    $(head).mouseover -> this.style["background-color"] = '#f1f1f1'
    $(head).mouseout -> this.style["background-color"] = ''

    body.style.display = 'none'

    frag.appendChild(head)
    frag.appendChild(body)

    frag

