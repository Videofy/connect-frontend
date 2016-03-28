EndPoint =
  url: (str)->
    (EndPoint.base or '') + (str or '')

module.exports = EndPoint
