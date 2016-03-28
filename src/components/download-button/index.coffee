ap = require('ap')
debug = require('debug')('connect:download-button')

exports = module.exports = (opts={}) ->
  type = opts.type
  from = opts.from
  tag = opts.tag ? "ul.download li a"

  return (v) ->
    download = (format, bitrate) ->
      debug('download', format, bitrate, link, @model)
      link = @model.packageUrl(format, bitrate)
      window.open(link, "_blank")

    v.on "click #{tag}", (e) ->
      e.preventDefault()
      e.stopPropagation()
      format = e.target.getAttribute("data-format")
      bitrate = e.target.getAttribute("data-bitrate") or undefined
      download.call @, format, bitrate

exports.template = require('./template')

