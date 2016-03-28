sort = require('sort-util')

util =
  row: (item, name)->
    tagName: 'tr'
    children: [
      tagName: 'td'
      textContent: item.title
    ,
      tagName: 'td'
      children: [
        tagName: 'button'
        className: 'ss fake'
        attributes:
          'remove-from': name
          identifier: item.id
        children: [
          tagName: 'i'
          className: 'fa fa-trash-o ss bg-danger-hover'
          identifier: item.id
        ]
      ]
    ]
  select: (name, options, variables)->
    obj =
      key: 'div'
      tagName: 'div'
      children: [
        {
          tagName: 'table'
          className: 'ss rows'
          children: [
            tagName: 'tbody'
            attributes:
              'selection-items': name
            children: []
          ]
        }
        {
          key: 'div'
          tagName: 'div'
          className: 'ss input-button'
          children: [
              key: 'selector'
              tagName: 'select'
              className: 'ss natural'
              attributes:
                'selection-for': name
            ,
              key: 'button'
              tagName: 'button'
              className: 'ss bg-action hover'
              textContent: "Add"
              attributes:
                'add-to': name
          ]
        }
      ]

    # Display existing selections
    obj.children[0].children[0].children = variables.map (item)->
      util.row(item, name)

    # Fill options
    obj.children[1].children[0].children = options.map (opt)->
      tagName: 'option'
      value: opt.value
      textContent: opt.text
      disabled: opt.disabled
      first: !!opt.first
      selected: !!opt.first
    .sort (a, b)->
      return -1 if a.first
      return 1 if b.first
      sort.stringsInsensitive(a.textContent, b.textContent)
    obj

module.exports = util
