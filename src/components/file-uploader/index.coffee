request = require("superagent")

# Depreciated
_send = (config)->
  data = new FormData()

  for file, i in config.files
    data.append 'file' + i, file

  $.ajax
    url: config.url
    type: "POST"
    xhr: ->
      xhr = $.ajaxSettings.xhr()
      if config.progress
        xhr.upload.addEventListener 'progress', config.progress or (->), false
      xhr
    data: data
    cache: false
    contentType: false
    processData: false
    success: ( response ) ->
      config.success and config.success(response)
    error: ( response ) ->
      config.error and config.error(response)

files = (opts, done)->
  opts.method ?= 'post'
  req = request[opts.method](opts.url)
    .set("Cache-Control", "no-cache")
  for file, i in opts.files
    req.attach("file#{i}", file, file.name)
  req.on 'progress', (e)-> # To trigger progress event after end is called.
  req.end(done)
  req

module.exports =
  send: _send
  files: files
