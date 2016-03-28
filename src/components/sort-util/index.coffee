assert = require('assert')
lens   = require('dot-lens')

module.exports = util =
  bools: (a, b)->
    sort = 0

    if a and not b
      sort = -1
    else if not a and b
      sort = 1
    else
      sort = 0

    return sort

  dates: (a, b)->
    assert(a instanceof Date)
    assert(b instanceof Date)

    sort = 0
    ai = isNaN(a.getTime())
    bi = isNaN(b.getTime())

    if ai && bi
      return 0
    else if !ai && bi
      return -1
    else if ai && !bi
      return 1

    if a > b
      sort = -1
    else if a < b
      sort = 1
    else
      sort = 0
    return sort

  dateStrings: (a, b)->
    util.dates(new Date(a), new Date(b))

  strings: (a, b)->
    sort = 0
    if a < b
      sort = -1
    else if a > b
      sort = 1
    sort

  stringsInsensitive: (a, b)->
    util.strings((a or '').toLowerCase(), (b or '').toLowerCase())

  stringsArrayInsensitive: (a, b)->
    util.stringsInsensitive(a.join(''), b.join(''))

  bucket: (arr, buckets) ->
    return arr if not buckets.length

    bucket = buckets[0]
    remaining = buckets.slice(1, buckets.length)

    repos = {}
    for v, i in arr
      key = bucket.key(v)
      repos[key] = [] if not repos[key]
      repos[key].push(v)

    keys = Object.keys(repos).sort(bucket.sort)
    flatten = []
    for key, i in keys
      items = if remaining then util.bucket(repos[key], remaining) else repos[key]
      flatten = flatten.concat(items)

    flatten

  model: (type, field, a, b) ->
    throw Error('You can\'t sort by model type') if type is 'model'
    util[type](a.get(field), b.get(field))

  modeldl: (type, field, order=1)->
    util.object type, "attributes." + field, order

  object: (type, field, order=1)->
    get = lens(field).get
    (a, b)->
      util[type](get(a), get(b)) * order

util.bool = util.bools
util.date = util.dates
util.number = util.strings
util.string = util.strings
