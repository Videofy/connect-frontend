module.exports = util =
  valsMatch: (obj1, obj2, key) ->
    k1 = obj1[key]
    k2 = obj2[key]
    k1IsObj = typeof k1 is "object"
    k2IsObj = typeof k2 is "object"

    if (k1IsObj and k2 is undefined) or (k2IsObj and k1 is undefined)
      return true
    if k1IsObj and k2IsObj
      return util.valsMatch(k1, k2, Object.keys(k1)[0])
    if k1 is k2 then return true else return false
