isValidStatus = (status)->
  status >= 200 and status < 300

module.exports =
  superagent: (err, res)->
    if res and !isValidStatus(res.status) and res.body?.message
      err = Error()
      _.extend(err, res.body)
    return err if err
    undefined
  backbone:
    error: (res)->
      err = Error('An unknown error occured.')
      try
        _.extend(err, JSON.parse(res.responseText))
      catch e
        err.message = res.responseText if res.responseText
      err
