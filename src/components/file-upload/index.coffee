
module.exports = (url, file, opts) ->
  return if file.val() is ""
  data = new FormData()

  files = file[0].files

  $.each files, (i, f) ->
    data.append 'file' + i, f

  $.ajax
    url: url
    type: 'POST'
    xhr: ->
      xhr = $.ajaxSettings.xhr()
      if opts.progress
        xhr.upload.addEventListener 'progress', opts.progress or (->), false
      xhr
    data: data
    cache: false
    contentType: false
    processData: false
    success: (r)  -> opts.success and opts.success(r, files)
    error: (r) -> opts.error and opts.error(r, files)
